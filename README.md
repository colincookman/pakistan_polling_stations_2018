Polling station level electoral returns
---------------------------------------

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
other polling stations we have only form 48 data (there are many missing
form 45s).

For most of the numeric variables there are three kinds of missing data:
- `NA`, or missing data: In this case the source of the missingness is
one of two things. For the `can_votes_*` variables these are NA if there
was no candidate for whom votes could be entered. For example, if a
polling station only had 20 candidates, then `can_votes_21` would be NA.
Another source of NAs is when merging with the form 45 data. Form 48
fields will be NA if the polling station only exists in the Form 45
data, and the same is true in reverse. - `-99`: Data entry operator
could not read the field, but it existed - `-88`: Data missing on hard
copy form

In some cases, some of the data differs across the two datasets. For
that reason, and to clearly denote which form has which data, we append
`_45` to data from the form 45s.

### Wide data variables

You can get the wide polling station level data in
[data/ps\_data\_wide.csv](data/ps_data_wide.csv).

-   constituency\_ps\_id: the pasted together constituency\_id and
    ps\_id, a unique identifier of the constituency-polling station
-   province
-   assembly
-   constituency\_id
-   constituency\_name
-   constituency\_id\_NA: the corresponding national assembly
    constituency (for the provincial assemblies)
-   ps\_id: the official serial number of the polling station
-   ps\_name: the name of the polling station

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
-   n\_candidates: the number of candidate registered in this
    constituency

Polling station level voting data:

-   male\_voters, female\_voters, total\_voters: the total number of
    registered voters, merged from the form 28 polling station-electoral
    area data
-   invalid\_votes, valid\_votes, total\_votes: the votes cast by
    category as recorded on the form 48s
-   turnout: `total_votes / total_voters`, the turnout comparing the
    registered voters on the form 28s to the number of votes on the form
    48s
-   ps\_valid\_votes\_summed: in most cases should be the same as
    `valid_votes`, but this comes from summing across the candidate
    votes (where none of them are missing), which in some cases is
    different from `valid_votes` where there are gaps in entry.
-   total\_male\_votes\_45, total\_female\_votes\_45, total\_votes\_45:
    total votes cast by gender from the form 45s; these are unofficial
    forms and may differ when summed from the `total_votes` column.
-   male\_turnout\_45, female\_turnout\_45, turnout\_45: turnout as
    defined by the gendered vote totals over the form 28 number of
    registered voters of that gender
    (e.g. `total_female_votes_45 / male_voters`)

Candidate level names, vote totals, parties, and vote share:

The asterices represent which candidate id (in the long version of the
data) we are referring to, and links the columns together.

-   candidate\_name\_\*
-   candidate\_votes\_\*
-   candidate\_party\_\*
-   candidate\_valid\_share\_\*: This is defined as the candidate\_votes
    over the `valid_votes` as found on the form 48s. Note there are some
    implausible outliers due to erroneous `valid_votes` totals.

Other:

-   ps\_name\_45: preserved for the few mismatches in names across forms
-   comments, comments\_45: comments by data entry operators about the
    data quality and matches across fields

TODO guess PS type (female, male, combined)

### Long data variables

[data/ps\_data\_long.csv](data/ps_data_long.csv)

TODO document

Electoral area data (Form 28s)
------------------------------

[data/electoral\_area\_ps\_data.csv](data/electoral_area_ps_data.csv)

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

Variables:

-   constituency\_ps\_id: *used to merge with PS level data*; the pasted
    together constituency\_id and ps\_id, a unique identifier of the
    constituency-polling station
-   constituency\_ps\_id\_block\_code: The above pasted with the
    block\_code to generate a unique identifier for each polling
    station-census block code.
-   province
-   assembly
-   constituency\_id
-   constituency\_area
-   ps\_id: the official serial number of the polling station
-   ps\_name\_from\_form28: the name of the polling station; not always
    consistent within `constituency_ps_id`, and may not match the
    `ps_name` from the polling station data
-   block\_code: the census block code; note, there are some
    `block_code` values that have dashes in them. These seem to
    represent more than one census block code (e.g. “332030301-06-07”
    seems to represent “332030301”, “332030306”, and “332030307”).
    Unfortunately this is how the census blocks were reported and we are
    unable to figure out which voters correspond to which of the census
    blocks. If you need help creating a full linking between polling
    stations and each of these block codes, please leave a message.
-   block\_code\_type: “Urban”, “Rural”, or “Unknown”
-   name\_ea\_rural: the name of the “rural” electoral area covered by
    this polling station-census block
-   name\_ea\_rural: the name of the “urban” electoral area covered by
    this polling station-census block
-   voter\_serials\_assigned\_to\_station: sometimes, the serial number
    range of the voters covered in this EA (per polling station) are
    reported. They are repeated here verbatim from the forms.
-   male\_voters: the number of registered male voters in this polling
    station-census block
-   female\_voters: the number of registered female voters in this
    polling station-census block
-   total\_voters: the number of registered voters in this polling
    station-census block
-   male\_booths: the number of assigned male booths for this polling
    station (Note: some errors seem to show different booths within
    polling station id in this dataset)
-   female\_booths: the number of assigned female booths for this
    polling station (Note: some errors seem to show different booths
    within polling station id in this dataset)
-   total\_booths: the total number of assigned booths for this polling
    station (Note: some errors seem to show different booths within
    polling station id in this dataset)
