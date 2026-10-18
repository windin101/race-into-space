extends GdUnitTestSuite
## Sentence case for the upstream ALL-CAPS prose: acronyms and proper nouns kept, everything
## else lower, each sentence capitalised, already mixed-case text untouched.


func test_acronyms_units_and_proper_nouns_survive() -> void:
	var s := TextCase.sentence("THE SOVIET STATE AND THE KGB ERASE YOUR NAME. PAY 10 M.B.'S TO NASA IN WASHINGTON.")
	assert_str(s).is_equal("The Soviet state and the KGB erase your name. Pay 10 MB to NASA in Washington.")


func test_sentence_starts_and_first_person() -> void:
	assert_str(TextCase.sentence("AND THAT'S THE NEWS. I'M CARTER WALCRITE.")).is_equal("And that's the news. I'm Carter Walcrite.")


func test_common_words_are_lower_mid_sentence() -> void:
	assert_str(TextCase.sentence("A MAJOR CORPORATION HAS DECIDED TO CREDIT THE SPACE AGENCY TODAY.")) \
		.is_equal("A major corporation has decided to credit the space agency today.")


func test_mixed_case_text_is_left_alone() -> void:
	assert_str(TextCase.sentence("Budget revised to 80 MB.")).is_equal("Budget revised to 80 MB.")


func test_hyphenated_names() -> void:
	assert_str(TextCase.sentence("ROBIN KNOX-JOHNSTON SAILS HOME.")).is_equal("Robin Knox-Johnston sails home.")
