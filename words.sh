#!/bin/bash
mkdir -p words

if [ "$USE_OFFICIAL" == "1" ]; then
	curl -s https://gist.githubusercontent.com/viandoxdev/e8d17f3990ad5b01bd9b2fe83ebe0fd7/raw/83906818a68014cde3f2a70d56f968fccc68f9b5/official_wordle_word_check -o words/word_check
	curl -s https://gist.githubusercontent.com/viandoxdev/e8d17f3990ad5b01bd9b2fe83ebe0fd7/raw/83906818a68014cde3f2a70d56f968fccc68f9b5/official_wordle_word_pool -o words/word_pool
	# the official wordle checks both for validity, here for the sake of simplicity we
	# only check the check list, and, therefore, need to duplicate some entries.
	cat words/word_pool >> words/word_check
else
	curl -s https://raw.githubusercontent.com/dwyl/english-words/master/words_alpha.txt -o words/all_check
	curl -s https://raw.githubusercontent.com/derekchuank/high-frequency-vocabulary/master/30k.txt -o words/all_pool

	f="$(mktemp)"

	tr -d '\r' < words/all_check > "$f" && mv "$f" words/all_check
	tr -d '\r' < words/all_pool > "$f" && mv "$f" words/all_pool
	# idk why but there's tabs in that file
	tr -d '\t' < words/all_pool > "$f" && mv "$f" words/all_pool

	is_uint() { case $1 in '' | *[!0-9]*) return 1;; esac ;}


	word_pool_size=${1:-1000}

	if ! is_uint "$word_pool_size"; then 
		echo "invalid word pool size"
		exit 1
	fi

	grep -x '^.\{5\}$' words/all_check > words/word_check
	grep -x '^.\{5\}$' words/all_pool | head -n"$word_pool_size" > words/word_pool
fi

{
	echo ".section .rodata"
	echo ".globl pool"
	echo ".globl check"
	echo ".globl pool_len"
	echo ".globl check_len"
	echo "pool: .ascii \"$(tr -d '\n' < words/word_pool | tr "[:lower:]" "[:upper:]")\""
	echo "check: .ascii \"$(tr -d '\n' < words/word_check | tr "[:lower:]" "[:upper:]")\""
	echo "pool_len: .quad $(wc -l < words/word_pool)"
	echo "check_len: .quad $(wc -l < words/word_check)"
	echo ".text"
} > words.s
