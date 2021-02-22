/* See LICENSE file for copyright and license details. */
#include <sys/stat.h>
#include <ctype.h>
#include <errno.h>
#include <fcntl.h>
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include <libkeccak.h>

#include "arg.h"


#ifndef URANDOM
# define URANDOM "/dev/urandom"
#endif


char *argv0;


static void
usage(void)
{
	fprintf(stderr, "usage: %s [-C capacity] [-N output-size] [-R rate] [-S state-size] [-W word-size] [-v]\n", argv0);
	exit(1);
}


static int
make_spec(struct libkeccak_generalised_spec *restrict gspec, struct libkeccak_spec *restrict spec)
{
	int r;

#define TEST(CASE, STR)  case LIBKECCAK_GENERALISED_SPEC_ERROR_##CASE:  return fprintf(stderr, "%s: %s\n", argv0, STR), 1;
	if (r = libkeccak_degeneralise_spec(gspec, spec), r) {
		switch (r) {
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
			fprintf(stderr, "%s: unknown error in algorithm parameters\n", argv0);
			return 1;
		}
	}
#undef TEST

#define TEST(CASE, STR)  case LIBKECCAK_SPEC_ERROR_##CASE:  return fprintf(stderr, "%s: %s\n", argv0, STR), 1;
	if (r = libkeccak_spec_check(spec), r) {
		switch (r) {
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
			fprintf(stderr, "%s: unknown error in algorithm parameters\n", argv0);
			return 1;
		}
	}
#undef TEST

	return 0;
}


int
main(int argc, char *argv[])
{
	char *restrict generated_random = NULL;
	struct libkeccak_generalised_spec gspec;
	struct libkeccak_spec spec;
	struct libkeccak_state state;
	size_t length, ptr;
	ssize_t got;
	int r, fd = -1, verbose = 0;
	long int *param;
	char *arg;

	memset(&state, 0, sizeof(struct libkeccak_state));
	libkeccak_generalised_spec_initialise(&gspec);

	errno = 0;
	ARGBEGIN {
	case 'R':
		param = &gspec.bitrate;
		goto set_param;
	case 'C':
		param = &gspec.capacity;
		goto set_param;
	case 'N':
	case 'O':
		param = &gspec.output;
		goto set_param;
	case 'S':
	case 'B':
		param = &gspec.state_size;
		goto set_param;
	case 'W':
		param = &gspec.word_size;
	set_param:
		arg = EARGF(usage());
		if (!isdigit(*arg))
			usage();
		*param = strtol(arg, &arg, 10);
		if (errno || *arg)
			usage();
		break;
	case 'v':
		verbose = 1;
		break;
	default:
		usage();
	} ARGEND;

	if (argc)
		usage();

	if ((r = make_spec(&gspec, &spec)))
		goto done;

	if (verbose) {
		fprintf(stderr, "%s: "        "rate: %li\n", argv0, gspec.bitrate);
		fprintf(stderr, "%s: "    "capacity: %li\n", argv0, gspec.capacity);
		fprintf(stderr, "%s: " "output size: %li\n", argv0, gspec.output);
		fprintf(stderr, "%s: "  "state size: %li\n", argv0, gspec.state_size);
		fprintf(stderr, "%s: "   "word size: %li\n", argv0, gspec.word_size);
	}

	libkeccak_state_initialise(&state, &spec);

	fd = open(URANDOM, O_RDONLY);
	if (fd < 0)
		goto fail;
	for (ptr = 0, length = sizeof(state.S); ptr < length;) {
		got = read(fd, (char*)(state.S) + ptr, length - ptr);
		if (got <= 0) {
			if (!got) {
				fprintf(stderr, "%s: %s contained less than %zu bytes\n", argv0, URANDOM, length);
				r = 2;
				goto done;
			}
			goto fail;
		}
		ptr += (size_t)got;
	}
	close(fd);
	fd = -1;

	length = (size_t)((spec.output + 7) / 8);
	generated_random = malloc(length);
	if (!generated_random)
		goto fail;

	for (;;) {
		libkeccak_squeeze(&state, generated_random);
		got = write(STDOUT_FILENO, generated_random, length);
		if (got < 0) {
			if (errno == EPIPE)
				break;
			goto fail;
		}
	}

done:
	if (fd >= 0)
		close(fd);
	free(generated_random);
	libkeccak_state_fast_destroy(&state);
	return r;

fail:
	perror(argv0);
	r = 2;
	goto done;
}
