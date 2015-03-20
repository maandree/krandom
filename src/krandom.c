/**
 * krandom – Keccak-based userspace pseudorandom number generator
 * Copyright © 2014  Mattias Andrée (maandree@member.fsf.org)
 * 
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 * 
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
#include <stdio.h>
#include <errno.h>
#include <fcntl.h>
#include <unistd.h>
#include <stddef.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <alloca.h>

#include <libkeccak.h>
#include <argparser.h>



#ifndef URANDOM
# ifndef DEVDIR
#  define DEVDIR  "/dev"
# endif
# define URANDOM  DEVDIR "/urandom"
#endif



#define USER_ERROR(string) 				\
  (fprintf(stderr, "%s: %s.\n", execname, string), 1)

#define ADD(arg, desc, ...)								\
  (arg ? args_add_option(args_new_argumented(NULL, arg, 0, __VA_ARGS__, NULL), desc)	\
       : args_add_option(args_new_argumentless(NULL, 0, __VA_ARGS__, NULL), desc))

#define LAST(arg)					\
  (args_opts_get(arg)[args_opts_get_count(arg) - 1])



/**
 * `argv[0]` from `main`
 */
static char* execname;


/**
 * Convert `libkeccak_generalised_spec_t` to `libkeccak_spec_t` and check for errors
 * 
 * @param   gspec  See `libkeccak_degeneralise_spec` 
 * @param   spec   See `libkeccak_degeneralise_spec` 
 * @return         Zero on success, an appropriate exit value on error
 */
static int make_spec(libkeccak_generalised_spec_t* restrict gspec, libkeccak_spec_t* restrict spec)
{
  int r;
  
#define TEST(CASE, STR)  case LIBKECCAK_GENERALISED_SPEC_ERROR_##CASE:  return USER_ERROR(STR)
  if (r = libkeccak_degeneralise_spec(gspec, spec), r)
    switch (r)
      {
	TEST (STATE_NONPOSITIVE,      "the state size must be positive");
	TEST (STATE_TOO_LARGE,        "the state size is too large, may not exceed 1600");
	TEST (STATE_MOD_25,           "the state size must be a multiple of 25");
	TEST (WORD_NONPOSITIVE,       "the word size must be positive");
	TEST (WORD_TOO_LARGE,         "the word size is too large, may not exceed 64");
	TEST (STATE_WORD_INCOHERENCY, "the state size must be exactly 25 times the word size");
	TEST (CAPACITY_NONPOSITIVE,   "the capacity must be positive");
	TEST (CAPACITY_MOD_8,         "the capacity must be a multiple of 8");
	TEST (BITRATE_NONPOSITIVE,    "the rate must be positive");
	TEST (BITRATE_MOD_8,          "the rate must be a multiple of 8");
	TEST (OUTPUT_NONPOSITIVE,     "the output size must be positive");
      default:
	return USER_ERROR("unknown error in algorithm parameters");
    }
#undef TEST
  
#define TEST(CASE, STR)  case LIBKECCAK_SPEC_ERROR_##CASE:  return USER_ERROR(STR)
  if (r = libkeccak_spec_check(spec), r)
    switch (r)
      {
      TEST (BITRATE_NONPOSITIVE,  "the rate size must be positive");
      TEST (BITRATE_MOD_8,        "the rate must be a multiple of 8");
      TEST (CAPACITY_NONPOSITIVE, "the capacity must be positive");
      TEST (CAPACITY_MOD_8,       "the capacity must be a multiple of 8");
      TEST (OUTPUT_NONPOSITIVE,   "the output size must be positive");
      TEST (STATE_TOO_LARGE,      "the state size is too large, may not exceed 1600");
      TEST (STATE_MOD_25,         "the state size must be a multiple of 25");
      TEST (WORD_NON_2_POTENT,    "the word size must be a power of 2");
      TEST (WORD_MOD_8,           "the word size must be a multiple of 8");
      default:
	return USER_ERROR("unknown error in algorithm parameters");
      }
#undef TEST
  
  return 0;
}



/**
 * Mane!
 * 
 * @param   argc  The number of elements in `argv`
 * @param   argv  Command line arguments
 * @return        Zero on and only on success
 */
int main(int argc, char** argv)
{
  char* restrict generated_random = NULL;
  libkeccak_generalised_spec_t gspec;
  libkeccak_spec_t spec;
  libkeccak_state_t state;
  size_t length, ptr;
  ssize_t got;
  int r, fd = -1, verbose = 0;
  
  execname = argc ? *argv : "krandom";
  
  
  memset(&state, 0, sizeof(libkeccak_state_t));
  libkeccak_generalised_spec_initialise(&gspec);
  if (!argc)
    goto skip_argv_parsing;
  
  args_init("Keccak-based userspace pseudorandom number generator",
	    "krandom [options...]", NULL,
	    NULL, 1, 0, args_standard_abbreviations);
   
  ADD(NULL,       "Display option summary", "-h", "--help");
  ADD("RATE",     "Select rate",            "-R", "--bitrate", "--rate");
  ADD("CAPACITY", "Select capacity",        "-C", "--capacity");
  ADD("SIZE",     "Select output size",     "-N", "-O", "--output-size", "--output");
  ADD("SIZE",     "Select state size",      "-S", "-B", "--state-size", "--state");
  ADD("SIZE",     "Select word size",       "-W", "--word-size", "--word");
  ADD(NULL,       "Be verbose",             "-v", "--verbose");
  
  args_parse(argc, argv);
  
  if (args_opts_used("-h"))  return args_help(0), args_dispose(), 0;
  if (args_opts_used("-R"))  gspec.bitrate    = atol(LAST("-R"));
  if (args_opts_used("-C"))  gspec.capacity   = atol(LAST("-C"));
  if (args_opts_used("-N"))  gspec.output     = atol(LAST("-N"));
  if (args_opts_used("-S"))  gspec.state_size = atol(LAST("-S"));
  if (args_opts_used("-W"))  gspec.word_size  = atol(LAST("-W"));
  if (args_opts_used("-v"))  verbose          = 1;
  
 skip_argv_parsing:
  if ((r = make_spec(&gspec, &spec)))
      goto done;
  
  if (verbose)
    {
      fprintf(stderr, "%s: "        "rate: %li\n", execname, gspec.bitrate);
      fprintf(stderr, "%s: "    "capacity: %li\n", execname, gspec.capacity);
      fprintf(stderr, "%s: " "output size: %li\n", execname, gspec.output);
      fprintf(stderr, "%s: "  "state size: %li\n", execname, gspec.state_size);
      fprintf(stderr, "%s: "   "word size: %li\n", execname, gspec.word_size);
    }
  
  libkeccak_state_initialise(&state, &spec);
  
  fd = open(URANDOM, O_RDONLY);
  if (fd < 0)
    goto fail;
  for (ptr = 0, length = sizeof(state.S); ptr < length;)
    {
      got = read(fd, (char*)(state.S) + ptr, length - ptr);
      if (got <= 0)
	goto fail;
      ptr += (size_t)got;
    }
  close(fd), fd = -1;
  
  length = (size_t)((spec.output + 7) / 8);
  generated_random = malloc(length);
  if (generated_random == NULL)
    goto fail;
  
  for (;;)
    {
      libkeccak_squeeze(&state, generated_random);
      got = write(STDOUT_FILENO, generated_random, length);
      if (got >= 0)
	continue;
      if (errno == EPIPE)
	break;
      goto fail;
    }
  
  
 done:
  if (fd >= 0)
    close(fd);
  if (argc)
    args_dispose();
  free(generated_random);
  libkeccak_state_fast_destroy(&state);
  return r;
 fail:
  perror(execname);
  r = 2;
  goto done;
}

