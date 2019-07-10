    library(haven)
    library(tidyverse)
    f28n <- read_dta("source_data/rcons_data/Form_28_NA_List.dta")
    f28p <- read_dta("source_data/rcons_data/Form_28_PROVINCIAL_List.dta")
    f45 <- read_dta("source_data/rcons_data/Form_45_Male_Female_Turnout.dta")
    f48 <- read_dta("source_data/rcons_data/Form_48_ResultForm.dta")
    f49 <- read_dta("source_data/rcons_data/Form_49_Candidate_List.dta")

\*\* THIS FILE CONTAINS A TEMPORARY SKELETON FOR THE FINAL RELEASE
DOCUMENTATION \*\*

Form 28s
--------

Each row in this data is unique to the combination of constituency,
polling station, and census block, and was released by the Electoral
Commission of Pakistan as Form 28.

Some polling station areas include several census blocks, and several
census blocks are across several polling stations. The mapping of
polling station to census block is many-to-many; this means that the
same polling Furthermore, female and male only polling stations can have
different mappings from polling station to census block.

The ECP released Form 28s separately for the National and Provincial
Assembly constituencies. While the delimitation of polling station areas
should be identical for the two constituencies, in the data they are
not. We report both of them here stacked together.

    f28 <- bind_rows(
      f28n %>% mutate(assembly = "National"), 
      f28p %>% 
        mutate(assembly = "Provincial") %>%
        select(-assembly_type)
    ) %>%
      mutate(
        constituency_ps_id = paste0(constituency_id, "_", ps_id),
        block_code_type = case_when(
          block_code_rural %in% c("0", "") & !(block_code_urban %in% c("0", "")) ~ "Urban",
          !(block_code_rural %in% c("0", "")) & block_code_urban %in% c("0", "") ~ "Rural",
          TRUE ~ "Unclear"
        ),
        block_code = ifelse(block_code == "0", NA, block_code)
      ) %>%
      select(province, assembly, constituency_id, constituency_area, ps_id, constituency_ps_id,
             ps_name, block_code, block_code_type, name_ea_rural, name_ea_urban, everything()) %>%
      select(-block_code_rural, -block_code_urban)

    glimpse(f28)

    ## Observations: 461,320
    ## Variables: 21
    ## $ province             <chr> "KPK", "KPK", "KPK", "KPK", "KPK", "KPK", "…
    ## $ assembly             <chr> "National", "National", "National", "Nation…
    ## $ constituency_id      <chr> "NA1", "NA1", "NA1", "NA1", "NA1", "NA1", "…
    ## $ constituency_area    <chr> "NA-1 CHITRAL", "NA-1 CHITRAL", "NA-1 CHITR…
    ## $ ps_id                <dbl> 1, 1, 2, 2, 3, 3, 4, 5, 6, 6, 6, 6, 6, 7, 7…
    ## $ constituency_ps_id   <chr> "NA1_1", "NA1_1", "NA1_2", "NA1_2", "NA1_3"…
    ## $ ps_name              <chr> "Govt; High School (GHS) Arrandu", "Govt; H…
    ## $ block_code           <chr> "1010101", "1010102", "1010103", "1010104",…
    ## $ block_code_type      <chr> "Rural", "Rural", "Rural", "Rural", "Rural"…
    ## $ name_ea_rural        <chr> "Arrandu Khas", "Arrandu", "Arrandu Suardam…
    ## $ name_ea_urban        <chr> "", "", "", "", "", "", "", "", "", "", "",…
    ## $ no_voters_on_ea      <chr> "", "", "", "", "", "", "", "", "", "", "",…
    ## $ male_voters          <dbl> 484, 252, 408, 118, 538, 115, 503, 403, 78,…
    ## $ female_voters        <dbl> 454, 194, 314, 93, 393, 58, 412, 351, 25, 1…
    ## $ total_voters         <dbl> 938, 446, 722, 211, 931, 173, 915, 754, 103…
    ## $ male_booths          <dbl> 2, 2, 1, 1, 2, 2, 1, 1, 2, 2, 2, 2, 2, 1, 1…
    ## $ female_booths        <dbl> 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1…
    ## $ total_booths         <dbl> 3, 3, 2, 2, 3, 3, 2, 2, 3, 3, 3, 3, 3, 2, 2…
    ## $ constituency_no_NA   <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA,…
    ## $ constituency_area_NA <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA,…
    ## $ ps_id_NA             <dbl> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA,…

    write_csv(f28, path = "data/electoral_area_form28.csv")

Variables:

-   province
-   assembly
-   constituency\_id
-   constituency\_area
-   ps\_id: the official serial number of the polling station
-   ps\_name: the name of the polling station
-   constituency\_ps\_id: the pasted together constituency\_id and
    ps\_id, a unique identifier of the constituency-polling station
-   block\_code: the census block code
-   block\_code\_type: “Urban”, “Rural”, or “Unknown”
-   name\_ea\_rural: the name of the “rural” electoral area covered by
    this polling station-census block
-   name\_ea\_rural: the name of the “urban” electoral area covered by
    this polling station-census block
-   no\_voters\_on\_ea: sometimes, the serial number range of the voters
    covered in this EA (per polling station) are reported. They are
    repeated here verbatim from the forms.
-   male\_voters: the number of registered male voters in this polling
    station-census block
-   female\_voters: the number of registered female voters in this
    polling station-census block
-   total\_voters: the number of registered voters in this polling
    station-census block
-   male\_booths: the number of assigned male booths for this polling
    station
-   female\_booths: the number of assigned female booths for this
    polling station
-   total\_booths: the total number of assigned booths for this polling
    station
-   constituency\_no\_NA: for provincial assembly polling stations, the
    national assembly constituency number that it also serves
-   constituency\_area\_NA: for provincial assembly polling stations,
    the national assembly constituency area that it also serves
-   ps\_id\_NA: for provincial assembly polling stations, the serial
    number the same polling station has at the national assembly level

Polling station level electoral returns
---------------------------------------

Next, we have the actual polling station level electoral returns, which
can be merged onto the above using the `constituency_ps_id` code.

These data are the official form 48s (polling station level returns by
candidate) and the unofficial form 45s, from which we collect
preliminary gender-based turnout. This should allow for analysis of
gender-based turnout, even in combined polling stations. Note the form
45s uploaded by the ECP were not the final, official forms for the
ratification of the election. Only the form 48s, which do not have
gendered turnout, are considered official.

Note that the release of these forms was *not* complete. Thus there is
not complete coverage, and in some case the sum of the polling station
totals is quite different from the reported constituency level returns.
Furthermore, for some polling stations we only have form 45 data and for
other polling stations we have only form 48 data.

In some cases, some of the data differs across the two datasets. For
that reason, and to clearly denote which form has which data, we append
`_45` to data from the form 45s.

    f48_clean <- f48 %>%
      mutate(
        constituency_ps_id = paste0(constituency_id, "_", ps_id)
      ) %>%
      select(-assembly_type)
    f45_clean <- f45 %>%
      mutate(
        constituency_ps_id = paste0(constituency_id, "_", ps_id)
      ) %>%
      select(-assembly_type)
    # Many missing f45s
    length(setdiff(f48_clean$constituency_ps_id, f45_clean$constituency_ps_id))

    ## [1] 116387

    # Few missing f48s (for which f45s exist)
    length(setdiff(f45_clean$constituency_ps_id, f48_clean$constituency_ps_id))

    ## [1] 2229

    intersect(names(f48_clean), names(f45_clean))

    ## [1] "province"           "constituency_id"    "ps_id"             
    ## [4] "ps_name"            "total_votes"        "comments"          
    ## [7] "constituency_ps_id"

    sanity_check <- full_join(
      f48_clean, 
      f45_clean,
      by = "constituency_ps_id"
    )
    # Sanity checks
    table(sanity_check$province.x == sanity_check$province.y)

    ## 
    ##  TRUE 
    ## 39727

    table(sanity_check$ps_name.x == sanity_check$ps_name.y)

    ## 
    ## FALSE  TRUE 
    ##   537 39190

    table(sanity_check$total_votes.x == sanity_check$total_votes.y)

    ## 
    ## FALSE  TRUE 
    ##     3 39666

    # Final merge
    ps_dat <- full_join(
      f48_clean, 
      f45_clean %>% 
        select(-constituency_id, -ps_id) %>%
        rename_at(vars(-constituency_ps_id), list(~paste0(., "_45"))),
      by = "constituency_ps_id"
    ) %>%
      mutate(
        province = ifelse(is.na(province), province_45, province),
        assembly = ifelse(grepl("^NA", constituency_id), "National", "Provincial")
      ) %>%
      rename_at(
        vars(registered_voters_male, registered_voters_female, registered_voters_total),
        list(~paste0("constituency_", .))
      ) %>%
      rename_at(
        vars(starts_with("total_number_ps")),
        list(~gsub("^total", "constituency", .))
      ) %>%
      rename(constituency_id_NA = constituency_no_NA) %>%
      select(province, assembly, constituency_id, constituency_name, ps_id, ps_name, everything())

    # TODO: clean negative values
    # TODO: merge in registered voter totals from form 28s
    # TODO: compute gendered and overall turnout values
    # TODO: create long version of data and merge with form 49s

-   province
-   assembly
-   constituency\_id
-   constituency\_name
-   constituency\_no\_NA: the corresponding national assembly
    constituency
-   constituency\_ps\_id: the pasted together constituency\_id and
    ps\_id, a unique identifier of the constituency-polling station

Some constituency level electoral data:

-   constituency\_registered\_voters\_male

-   constituency\_registered\_voters\_female

-   constituency\_registered\_voters\_total

-   constituency\_number\_ps\_male: number of male-only polling stations
    in the constituency

-   constituency\_number\_ps\_female: number of female-only polling
    stations in the constituency

-   constituency\_number\_ps\_combined: number of combined polling
    stations in the constituency

-   constituency\_number\_ps\_total: total number of polling stations in
    the constituency

-   ps\_id: the official serial number of the polling station

-   ps\_name: the name of the polling station

Candidate level names and vote totals:

-   can\_name\_\*
-   can\_votes\_\*

To match candidates to more, see the long version of the data and the
form 49s below.

Form 45 data:

-   ps\_name\_45: preserved for the few mismatches in names across forms

-   total\_votes\_45, total\_turnout\_45: supposedly both the same
    number, reported separately on the forms

-   total\_female\_turnout\_45: the reported number of women who turned
    out; 0 =

-   total\_male\_turnout\_45: the reported number of men who turned out

-   comments, comments\_45: comments by data entry operators about the
    data quality and matches across fields
