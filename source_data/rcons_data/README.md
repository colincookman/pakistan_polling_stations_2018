This file cleans the RCons data for publication.

    ## ── Attaching packages ───────────────────────────────── tidyverse 1.2.1 ──

    ## ✔ ggplot2 3.2.1     ✔ purrr   0.3.2
    ## ✔ tibble  2.1.3     ✔ dplyr   0.8.3
    ## ✔ tidyr   0.8.2     ✔ stringr 1.4.0
    ## ✔ readr   1.1.1     ✔ forcats 0.3.0

    ## ── Conflicts ──────────────────────────────────── tidyverse_conflicts() ──
    ## ✖ dplyr::filter() masks stats::filter()
    ## ✖ dplyr::lag()    masks stats::lag()

    # Form 28 data
    f28 <- bind_rows(
      f28n %>% mutate(assembly = "National"), 
      f28p %>% 
        mutate(assembly = "Provincial") %>%
        select(-assembly_type)
    ) %>%
      mutate(
        block_code = ifelse(block_code %in% c("-88", "0"), NA, block_code),
        constituency_ps_id = paste0(constituency_id, "_", ps_id),
        block_code_type = case_when(
          block_code_rural %in% c("0", "") & !(block_code_urban %in% c("0", "")) ~ "Urban",
          !(block_code_rural %in% c("0", "")) & block_code_urban %in% c("0", "") ~ "Rural",
          TRUE ~ "Unclear"
        ),
        # Fix obvious typos in inconsistent polling station names
        ps_name_from_form28 = case_when(
          constituency_ps_id == "PB17_10" & ps_name == "(2) LIBRARY HALL MACH (MALE)" ~ "LIBRARY HALL MACH (MALE)",
          constituency_ps_id %in% c("PB17_28", "PB17_29") & ps_name == "GOVT BOYS HIGH SCHOOL RIND ALI (MALE)" ~ "2 GOVT HIGH SCHOOL RIND ALI MALE",
          constituency_ps_id == "PB17_62" & ps_name == "BOYS P/S KHARA COMBINED" ~ "BOYS H/S BHERI COMBINED",
          TRUE ~ ps_name
        ),
        # Note: there remain some inconsistencies that it is unclear how to solve
        # When possible, prefer PS names from ps data
        
        # Create unique code
        constituency_ps_id_block_code = paste0(constituency_ps_id, "_", block_code),
        
        # Fix female and male NAs when it's very likely they should be 0
        female_voters = case_when(
          is.na(female_voters) & male_voters > 0 & male_booths > 0 & female_booths == 0 ~ 0,
          female_voters < 0 ~ NA_real_,
          TRUE ~ female_voters
        ),
        male_voters = case_when(
          is.na(male_voters) & female_voters > 0 & female_booths > 0 & male_booths == 0 ~ 0,
          male_voters < 0 ~ NA_real_,
          TRUE ~ male_voters
        ),
        # Fix unnecessary errors in total_voters and make safe assumptions about when
        # Female and male voters are missing and total should be present
        total_voters = case_when(
          total_voters < 0 ~ NA_real_,
          is.na(total_voters) & male_voters >= 0  & female_voters >= 0 | constituency_ps_id == "NA27_153" ~ male_voters + female_voters,
          total_voters == 0 & is.na(male_voters) & is.na(female_voters) ~ NA_real_,
          TRUE ~ total_voters
        )
      ) %>%
      rename(voter_serials_assigned_to_station = no_voters_on_ea) %>%
      # mutate_at(
      #   vars(ends_with("_booths"), ends_with("_voters")),
      #   list(
      #     ~case_when(
      #       is.na(.) ~electoral_area_ps_data.csv -88,
      #       . == -77 ~ -88,
      #       TRUE ~ .
      #     )
      #   )
      # ) %>%
      select(constituency_ps_id_block_code, constituency_ps_id, province, assembly, constituency_id, constituency_area, ps_id,
             ps_name_from_form28, block_code, block_code_type, name_ea_rural, name_ea_urban, everything()) %>%
      select(-block_code_rural, -block_code_urban, -constituency_no_NA, -constituency_area_NA, -ps_id_NA, -ps_name) %>%
      mutate_at(
        vars(ends_with("_voters")),
        as.integer
      )

    # Demonstrate that booths are not always fixed within polling station
    # ps_booths <- f28 %>% 
    #   group_by(constituency_ps_id) %>%
    #   summarize_at(vars(ends_with("_booths")), list(unique=~length(unique(.)))) %>%
    #   filter_at(vars(ends_with("_booths")), any_vars(. != 1))

    # Some inconsistent names within constituency_ps_id
    # ps_names <- f28 %>% 
    #   group_by(constituency_ps_id) %>%
    #   summarize(n_ps_names = length(unique(ps_name_from_form28))) %>%
    #   filter(n_ps_names != 1)
    # f28 %>% 
    #   left_join(ps_names) %>%
    #   filter(!is.na(n_ps_names)) %>%
    #   select(constituency_ps_id, ps_name_from_form28, name_ea_rural, name_ea_urban) %>%
    #   as.data.frame

    # Check values on voters and booths
    # f28 %>%
    #   filter_at(vars(ends_with("voters"), ends_with("booths")), any_vars(. < 0 | is.na(.))) %>%
    #   head() %>% as.data.frame
    # filter(f28, is.na(female_booths)) %>% as.data.frame
    # 
    # table(f28$male_booths, f28$female_booths, useNA = "a")
    # table(f28$total_booths, useNA = "a")
    # 
    # f28 %>%
    #   mutate_at(vars(ends_with("voters")), list(~case_when(. > 0 ~ 1, TRUE ~ .))) %>%
    #   with(., table(male_voters, female_voters, total_voters, useNA = "a"))
    # 
    # f28 %>%
    #   filter(total_voters == 0, male_voters > 0 | is.na(female_voters)) %>%
    #   as.data.frame()
    # 
    # f28 %>%
    #   filter(total_voters > 0, male_voters == 0, female_voters == 0) %>%
    #   as.data.frame()

    # f28 %>%
    #   filter(total_voters < 0 | is.na(total_voters)) %>%
    #   as.data.frame()

    # put the text block_codes and voter serials first so readr guesses character
    write_csv(f28 %>% arrange(desc(constituency_id == "NA204" | grepl("[a-z]", voter_serials_assigned_to_station))), path = "data/electoral_area_ps_data.csv")

    f28_ps_level <- f28 %>%
      group_by(constituency_ps_id) %>%
      summarize_at(vars(ends_with("_voters")), list(~sum(.)))

    # Polling station returns
    f48_clean <- f48 %>%
      mutate_at(
        vars(total_votes, valid_votes, invalid_votes),
        list(~{ifelse(. < 0, NA, .)})
      ) %>%
      mutate(
        constituency_ps_id = paste0(constituency_id, "_", ps_id),
        assembly = ifelse(grepl("^NA", constituency_id), "National", "Provincial"),
        # There are 62 cases in which total_votes is missing
        # but both valid_votes and invalid_votes exist
        # In those cases we can just impute total votes
        total_votes = case_when(
          is.na(total_votes) & !is.na(valid_votes) & !is.na(invalid_votes) ~ valid_votes + invalid_votes,
          TRUE ~ total_votes
        ),
        # Similarly other cases where the total and one of the other
        # numbers is known, and we can fill in the third
        valid_votes = case_when(
          is.na(valid_votes) & !is.na(total_votes) & !is.na(invalid_votes) ~ total_votes - invalid_votes,
          TRUE ~ valid_votes
        ),
        # There are two cases where total_votes is less than valid votes and invalid is missing
        # This is clearly a mistake
        invalid_votes = case_when(
          is.na(invalid_votes) & !is.na(total_votes) & !is.na(valid_votes) & total_votes - valid_votes > 0 ~ total_votes - valid_votes,
          TRUE ~ invalid_votes
        ),
        # Fix a typo
        can_votes_11 = ifelse(constituency_ps_id == "NA79_50", can_votes_12, can_votes_11),
        can_votes_12 = ifelse(constituency_ps_id == "NA79_50", can_votes_13, can_votes_12),
        can_votes_13 = ifelse(constituency_ps_id == "NA79_50", can_votes_14, can_votes_13),
        can_votes_14 = ifelse(constituency_ps_id == "NA79_50", can_votes_15, can_votes_14),
        can_votes_15 = ifelse(constituency_ps_id == "NA79_50", NA, can_votes_15),
      ) %>%
      select(-assembly_type)

    # Check vote totals data
    f48 %>%
      mutate_at(vars(ends_with("votes")), list(~case_when(. > 0 ~ 1, TRUE ~ .))) %>%
      with(., table(valid_votes, invalid_votes, total_votes, useNA = "a"))

    ## , , total_votes = -99
    ## 
    ##            invalid_votes
    ## valid_votes    -99    -88      0      1   <NA>
    ##        -99     254      0      0     12      0
    ##        -88       0      0      0      0      0
    ##        0         0      0      0      0      0
    ##        1        59      0      0     21      0
    ##        <NA>      0      0      0      0      0
    ## 
    ## , , total_votes = -88
    ## 
    ##            invalid_votes
    ## valid_votes    -99    -88      0      1   <NA>
    ##        -99       0      1      0      0      0
    ##        -88       0   1491      0      0      0
    ##        0         0      0      0      0      0
    ##        1         1   3532      1     40      0
    ##        <NA>      0      0      0      0      0
    ## 
    ## , , total_votes = 0
    ## 
    ##            invalid_votes
    ## valid_votes    -99    -88      0      1   <NA>
    ##        -99       0      0      0      0      0
    ##        -88       0      0      0      0      0
    ##        0         0      0    167      0      0
    ##        1         0      0      0      0      0
    ##        <NA>      0      0      0      0      0
    ## 
    ## , , total_votes = 1
    ## 
    ##            invalid_votes
    ## valid_votes    -99    -88      0      1   <NA>
    ##        -99      13      0      0      0      0
    ##        -88       0      0      0      0      0
    ##        0         0      0      0      4      0
    ##        1         7      0   4211 146300      0
    ##        <NA>      0      0      0      0      0
    ## 
    ## , , total_votes = NA
    ## 
    ##            invalid_votes
    ## valid_votes    -99    -88      0      1   <NA>
    ##        -99       0      0      0      0      0
    ##        -88       0      0      0      0      0
    ##        0         0      0      0      0      0
    ##        1         0      0      0      0      0
    ##        <NA>      0      0      0      0      0

    with(
      filter(f48, valid_votes >=  0 & invalid_votes >= 0),
      table(valid_votes + invalid_votes == total_votes)
    )

    ## 
    ##  FALSE   TRUE 
    ##     62 150682

    with(
      filter(f48_clean, valid_votes >=  0 & invalid_votes >= 0),
      table(valid_votes + invalid_votes == total_votes)
    )

    ## 
    ##   TRUE 
    ## 150748

    f48_clean %>%
      mutate_at(vars(ends_with("votes")), list(~case_when(. > 0 ~ 1, TRUE ~ .))) %>%
      with(., table(valid_votes, invalid_votes, total_votes, useNA = "a"))

    ## , , total_votes = 0
    ## 
    ##            invalid_votes
    ## valid_votes      0      1   <NA>
    ##        0       167      0      0
    ##        1         0      0      0
    ##        <NA>      0      0      0
    ## 
    ## , , total_votes = 1
    ## 
    ##            invalid_votes
    ## valid_votes      0      1   <NA>
    ##        0         0      4      0
    ##        1      4212 146365      3
    ##        <NA>      0      0     13
    ## 
    ## , , total_votes = NA
    ## 
    ##            invalid_votes
    ## valid_votes      0      1   <NA>
    ##        0         0      0      0
    ##        1         0      0   3592
    ##        <NA>      0     12   1746

    # Check constituency data
    names(f48_clean)

    ##   [1] "province"                 "constituency_id"         
    ##   [3] "constituency_name"        "constituency_no_NA"      
    ##   [5] "registered_voters_male"   "registered_voters_female"
    ##   [7] "registered_voters_total"  "total_number_ps_male"    
    ##   [9] "total_number_ps_female"   "total_number_ps_combined"
    ##  [11] "total_number_ps_total"    "ps_id"                   
    ##  [13] "ps_name"                  "can_name_1"              
    ##  [15] "can_votes_1"              "can_name_2"              
    ##  [17] "can_votes_2"              "can_name_3"              
    ##  [19] "can_votes_3"              "can_name_4"              
    ##  [21] "can_votes_4"              "can_name_5"              
    ##  [23] "can_votes_5"              "can_name_6"              
    ##  [25] "can_votes_6"              "can_name_7"              
    ##  [27] "can_votes_7"              "can_name_8"              
    ##  [29] "can_votes_8"              "can_name_9"              
    ##  [31] "can_votes_9"              "can_name_10"             
    ##  [33] "can_votes_10"             "can_name_11"             
    ##  [35] "can_votes_11"             "can_name_12"             
    ##  [37] "can_votes_12"             "can_name_13"             
    ##  [39] "can_votes_13"             "can_name_14"             
    ##  [41] "can_votes_14"             "can_name_15"             
    ##  [43] "can_votes_15"             "can_name_16"             
    ##  [45] "can_votes_16"             "can_name_17"             
    ##  [47] "can_votes_17"             "can_name_18"             
    ##  [49] "can_votes_18"             "can_name_19"             
    ##  [51] "can_votes_19"             "can_name_20"             
    ##  [53] "can_votes_20"             "can_name_21"             
    ##  [55] "can_votes_21"             "can_name_22"             
    ##  [57] "can_votes_22"             "can_name_23"             
    ##  [59] "can_votes_23"             "can_name_24"             
    ##  [61] "can_votes_24"             "can_name_25"             
    ##  [63] "can_votes_25"             "can_name_26"             
    ##  [65] "can_votes_26"             "can_name_27"             
    ##  [67] "can_votes_27"             "can_name_28"             
    ##  [69] "can_votes_28"             "can_name_29"             
    ##  [71] "can_votes_29"             "can_name_30"             
    ##  [73] "can_votes_30"             "can_name_31"             
    ##  [75] "can_votes_31"             "can_name_32"             
    ##  [77] "can_votes_32"             "can_name_33"             
    ##  [79] "can_votes_33"             "can_name_34"             
    ##  [81] "can_votes_34"             "can_name_35"             
    ##  [83] "can_votes_35"             "can_name_36"             
    ##  [85] "can_votes_36"             "can_name_37"             
    ##  [87] "can_votes_37"             "can_name_38"             
    ##  [89] "can_votes_38"             "can_name_39"             
    ##  [91] "can_votes_39"             "can_name_40"             
    ##  [93] "can_votes_40"             "can_name_41"             
    ##  [95] "can_votes_41"             "can_name_42"             
    ##  [97] "can_votes_42"             "can_name_43"             
    ##  [99] "can_votes_43"             "can_name_44"             
    ## [101] "can_votes_44"             "can_name_45"             
    ## [103] "can_votes_45"             "valid_votes"             
    ## [105] "invalid_votes"            "total_votes"             
    ## [107] "comments"                 "constituency_ps_id"      
    ## [109] "assembly"

    f48_clean %>%
      mutate_at(vars(starts_with("registered")), list(~case_when(. > 0 ~ 1, TRUE ~ .))) %>%
      with(., table(registered_voters_male, registered_voters_female, registered_voters_total, useNA = "a"))

    ## , , registered_voters_total = -198
    ## 
    ##                       registered_voters_female
    ## registered_voters_male    -99    -88      1   <NA>
    ##                   -99     156      0      0      0
    ##                   -88       0      0      0      0
    ##                   1         0      0      0      0
    ##                   <NA>      0      0      0      0
    ## 
    ## , , registered_voters_total = -88
    ## 
    ##                       registered_voters_female
    ## registered_voters_male    -99    -88      1   <NA>
    ##                   -99       0      0      0      0
    ##                   -88       0   1266      0      0
    ##                   1         0      0      0      0
    ##                   <NA>      0      0      0      0
    ## 
    ## , , registered_voters_total = 1
    ## 
    ##                       registered_voters_female
    ## registered_voters_male    -99    -88      1   <NA>
    ##                   -99       0      0      0      0
    ##                   -88       0      0      0      0
    ##                   1         0      0 154692      0
    ##                   <NA>      0      0      0      0
    ## 
    ## , , registered_voters_total = NA
    ## 
    ##                       registered_voters_female
    ## registered_voters_male    -99    -88      1   <NA>
    ##                   -99       0      0      0      0
    ##                   -88       0      0      0      0
    ##                   1         0      0      0      0
    ##                   <NA>      0      0      0      0

    f48_clean %>%
      mutate_at(vars(starts_with("total_number")), list(~case_when(. > 0 ~ 1, TRUE ~ .))) %>%
      with(., table(total_number_ps_female, total_number_ps_combined, total_number_ps_total, useNA = "a"))

    ## , , total_number_ps_total = -352
    ## 
    ##                       total_number_ps_combined
    ## total_number_ps_female    -99    -88      0      1   <NA>
    ##                   -99       0      0      0      0      0
    ##                   -88       0    383      0      0      0
    ##                   0         0      0      0      0      0
    ##                   1         0      0      0      0      0
    ##                   <NA>      0      0      0      0      0
    ## 
    ## , , total_number_ps_total = -297
    ## 
    ##                       total_number_ps_combined
    ## total_number_ps_female    -99    -88      0      1   <NA>
    ##                   -99     159      0      0      0      0
    ##                   -88       0      0      0      0      0
    ##                   0         0      0      0      0      0
    ##                   1         0      0      0      0      0
    ##                   <NA>      0      0      0      0      0
    ## 
    ## , , total_number_ps_total = -264
    ## 
    ##                       total_number_ps_combined
    ## total_number_ps_female    -99    -88      0      1   <NA>
    ##                   -99       0      0      0      0      0
    ##                   -88       0    984      0      0      0
    ##                   0         0      0      0      0      0
    ##                   1         0      0      0      0      0
    ##                   <NA>      0      0      0      0      0
    ## 
    ## , , total_number_ps_total = 0
    ## 
    ##                       total_number_ps_combined
    ## total_number_ps_female    -99    -88      0      1   <NA>
    ##                   -99       0      0      0      0      0
    ##                   -88       0      0      0      0      0
    ##                   0         0      0    458      0      0
    ##                   1         0      0      0      0      0
    ##                   <NA>      0      0      0      0      0
    ## 
    ## , , total_number_ps_total = 1
    ## 
    ##                       total_number_ps_combined
    ## total_number_ps_female    -99    -88      0      1   <NA>
    ##                   -99       0      0      0      0      0
    ##                   -88       0      0      0      0      0
    ##                   0         0      0      0   2613      0
    ##                   1         0      0   2256 149261      0
    ##                   <NA>      0      0      0      0      0
    ## 
    ## , , total_number_ps_total = NA
    ## 
    ##                       total_number_ps_combined
    ## total_number_ps_female    -99    -88      0      1   <NA>
    ##                   -99       0      0      0      0      0
    ##                   -88       0      0      0      0      0
    ##                   0         0      0      0      0      0
    ##                   1         0      0      0      0      0
    ##                   <NA>      0      0      0      0      0

    table(duplicated(f48_clean$constituency_ps_id))

    ## 
    ##  FALSE 
    ## 156114

    f48_long <- f48_clean %>%
      select(constituency_id, constituency_ps_id, invalid_votes, valid_votes, total_votes, starts_with("can_")) %>%
      gather(key, value, starts_with("can_")) %>%
      mutate(key = gsub("can_", "", key)) %>%
      separate(key, into = c("variable", "candidate_id")) %>%
      spread(variable, value) 


    f48_merged_f49 <- f48_long %>%
      filter(!(is.na(votes) & name == "")) %>%
      mutate(
        candidate_id = as.integer(candidate_id),
        votes = as.integer(votes),
        votes = ifelse(
          votes < 0,
          NA_integer_,
          votes
        )
      ) %>%
      left_join(
        f49 %>%
          mutate(
            candidate_id = as.integer(candidate_id),
            candidate_total_valid_votes_polled_49 = as.integer(gsub("\\*", "", valid_votes_polled)),
            comments_49 = comments
          ) %>%
          select(constituency_id, candidate_id, party_affiliation, candidate_total_valid_votes_polled_49, comments_49)
      )

    ## Joining, by = c("constituency_id", "candidate_id")

    f48_long_clean <- f48_merged_f49 %>%
      group_by(constituency_ps_id) %>%
      mutate(
        ps_valid_votes_summed = sum(ifelse(votes < 0, NA, votes)),
        n_candidates = max(candidate_id)
      ) %>%
      group_by(constituency_id, candidate_id) %>%
      mutate(
        candidate_total_valid_votes_summed = sum(ifelse(votes < 0, NA, votes)),
        candidate_valid_share = case_when(
          votes < 0 | valid_votes < 0 ~ NA_real_,
          TRUE ~ votes / valid_votes
        ),
        candidate_valid_share_of_summed = case_when(
          votes < 0 | ps_valid_votes_summed < 0 ~ NA_real_,
          TRUE ~ votes / ps_valid_votes_summed
        )
      ) %>%
      rename(
        candidate_votes = votes,
        candidate_name = name,
        candidate_party = party_affiliation
      ) %>%
      mutate_at(
        vars(ends_with("voters"), ends_with("votes"), ends_with("_voters_total")),
        as.integer
      )

    f48_wide_w_long_vars <- f48_long_clean %>%
      group_by(constituency_ps_id) %>%
      summarize_at(vars(n_candidates, ps_valid_votes_summed), unique)
    # Don't use sum candidate votes because many missing polling stations!

    names(f48_long_clean)

    ##  [1] "constituency_id"                      
    ##  [2] "constituency_ps_id"                   
    ##  [3] "invalid_votes"                        
    ##  [4] "valid_votes"                          
    ##  [5] "total_votes"                          
    ##  [6] "candidate_id"                         
    ##  [7] "candidate_name"                       
    ##  [8] "candidate_votes"                      
    ##  [9] "candidate_party"                      
    ## [10] "candidate_total_valid_votes_polled_49"
    ## [11] "comments_49"                          
    ## [12] "ps_valid_votes_summed"                
    ## [13] "n_candidates"                         
    ## [14] "candidate_total_valid_votes_summed"   
    ## [15] "candidate_valid_share"                
    ## [16] "candidate_valid_share_of_summed"

    f48_wide_merge_from_long <- f48_long_clean %>%
      ungroup() %>%
      select(candidate_name, candidate_id, candidate_votes, candidate_party, candidate_valid_share, constituency_ps_id) %>%
      gather(
        key, val,
        candidate_name, candidate_votes, candidate_party, candidate_valid_share
      ) %>%
      mutate(
        key = paste0(gsub("_copy", "", key), "_", as.character(candidate_id))
      ) %>%
      select(-candidate_id) %>%
      spread(key, val) %>%
      mutate_at(vars(starts_with("candidate_valid_share")), as.numeric)

    # clean f45 data
    f45_clean <- f45 %>%
      mutate(
        constituency_ps_id = paste0(constituency_id, "_", ps_id)
      ) %>%
      select(-assembly_type)

    f45_merge <- f45_clean %>% 
      select(-constituency_id, -ps_id) %>%
      mutate(
        total_turnout = case_when(
          total_votes >= 0 & !is.na(total_votes) & (total_turnout < 0 | is.na(total_turnout)) ~ total_votes,
          TRUE ~ total_turnout
        )
      ) %>%
      rename_at(vars(-constituency_ps_id), list(~paste0(., "_45"))) %>%
      mutate_at(vars(contains("turnout_45")), list(~ifelse(. < 0, NA, .))) %>%
      select(-total_votes_45) %>%
      rename_at(vars(ends_with("turnout_45")), list(~gsub("turnout", "votes", .)))

    f45_merge %>%
      mutate_at(vars(ends_with("votes_45")), list(~case_when(. > 0 ~ 1, TRUE ~ .))) %>%
      with(., table(total_female_votes_45, total_male_votes_45,total_votes_45, useNA = "a"))

    ## , , total_votes_45 = 0
    ## 
    ##                      total_male_votes_45
    ## total_female_votes_45     0     1  <NA>
    ##                  0        5     0     0
    ##                  1        0     0     0
    ##                  <NA>     0     0     9
    ## 
    ## , , total_votes_45 = 1
    ## 
    ##                      total_male_votes_45
    ## total_female_votes_45     0     1  <NA>
    ##                  0        0   395     0
    ##                  1       15 38202    13
    ##                  <NA>     0   221  2398
    ## 
    ## , , total_votes_45 = NA
    ## 
    ##                      total_male_votes_45
    ## total_female_votes_45     0     1  <NA>
    ##                  0        0     0     0
    ##                  1        0     0     0
    ##                  <NA>     0     1   697

    # Create final wide data
    f48_wide_ready <- f48_clean %>% 
      select(-starts_with("can")) %>%
      left_join(f48_wide_merge_from_long) %>%
      left_join(f45_merge) %>%
      left_join(f28_ps_level) %>%
      left_join(f48_wide_w_long_vars) %>%
      rename_at(
        vars(starts_with("total_number_ps")),
        list(~gsub("^total", "constituency", .))
      ) %>%
      rename_at(
        vars(starts_with("registered_")),
        list(~paste0("constituency_", .))
      ) %>%
      rename(constituency_id_NA = constituency_no_NA) %>%
      mutate(
        total_voters = ifelse(total_voters < 0, NA, total_voters),
        turnout = ifelse(
          total_votes < 0, 
          total_votes, 
          total_votes / total_voters
        ),
        turnout_45 = ifelse(
          total_votes_45 < 0, 
          total_votes_45, 
          total_votes_45 / total_voters
        ),
        male_turnout_45 = ifelse(
          total_male_votes_45 < 0,
          total_male_votes_45, 
          total_male_votes_45 / male_voters
        ),
        female_turnout_45 = ifelse(
          total_female_votes_45 < 0,
          total_female_votes_45, 
          total_female_votes_45 / female_voters
        )
      ) %>%
      mutate_at(
        vars(contains("turnout")),
        list(~{ifelse(is.infinite(.), NA, .)})
      ) %>%
      mutate_at(
        vars(ends_with("voters"), ends_with("votes"), ends_with("_voters_total"), matches("votes_[0-9]{1,3}"),
             ps_valid_votes_summed, n_candidates),
        as.integer
      ) %>%
      mutate_at(
        vars(female_voters, male_voters, total_male_votes_45, total_female_votes_45, female_turnout_45, male_turnout_45),
        list(class = ~{
          case_when(
            . < 0 ~ "Neg",
            . == 0 ~ "Zero",
            . > 0 ~ "Pos"
          )
        })
      ) %>%
      mutate(
        ps_gender_type = case_when(
          male_voters_class == "Pos" & female_voters_class == "Pos" ~ "Combined",
          male_voters_class == "Zero" & female_voters_class == "Pos" ~ "Female only",
          male_voters_class == "Pos" & female_voters_class == "Zero" ~ "Male only",
          TRUE ~ "Unknown"
        )
      ) %>%
      mutate_at(
        vars(total_female_votes_45, female_turnout_45, total_male_votes_45, total_female_votes_45, comments_45, total_votes_45),
        list(~{ifelse(ps_gender_type != "Combined", NA, .)})
      ) %>%
      select(constituency_ps_id, province, assembly, constituency_id, constituency_name, constituency_id_NA, ps_id, ps_name, 
             starts_with('constituency_number'), starts_with("constituency_registered_voters"), n_candidates,
             male_voters, female_voters, total_voters,
             valid_votes, invalid_votes, total_votes, turnout,
             ps_valid_votes_summed,
             total_male_votes_45, total_female_votes_45, total_votes_45,
             male_turnout_45, female_turnout_45, turnout_45,
             everything()) %>%
      select(-province_45, -ends_with("_class"))

    ## Joining, by = "constituency_ps_id"

    ## Joining, by = "constituency_ps_id"
    ## Joining, by = "constituency_ps_id"
    ## Joining, by = "constituency_ps_id"

    write_csv(
      f48_long_clean %>%
        rename(
          ps_invalid_votes = invalid_votes,
          ps_valid_votes = valid_votes,
          ps_total_votes = total_votes
        ) %>%
        select(constituency_id, constituency_ps_id, candidate_id, candidate_name,
               candidate_party, candidate_votes,
               candidate_valid_share, candidate_valid_share_of_summed,
               candidate_total_valid_votes_summed, candidate_total_valid_votes_polled_49,
               ps_invalid_votes, ps_valid_votes, ps_total_votes, ps_valid_votes_summed, n_candidates), 
      path = "data/ps_data_long.csv"
    )
    write_csv(f48_wide_ready, path = "data/ps_data_wide.csv")

    # Many missing f45s
    length(setdiff(f48_clean$constituency_ps_id, f45_clean$constituency_ps_id))

    ## [1] 116387

    # Few missing f48s (for which f45s exist)
    length(setdiff(f45_clean$constituency_ps_id, f48_clean$constituency_ps_id))

    ## [1] 2229
