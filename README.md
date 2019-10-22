This repository hosts links to and documentation for several detailed
datasets regarding the 2018 General Elections in Pakistan. These data
were released by the Election Commission of Pakistan, largely in scanned
PDFs and incomplete in their coverage. They have been manually entered
by a team of data entry operators and somewhat cleaned to improve their
ease of use for researchers, journalists, policy makers, and others.

There are bound to be some errors in these data. Please report them by
filing an issue above or sending [Luke Sonnet](lukesonnet.com) an email.

All the data is held in an accompanying Open Science Framework
repository. If you use the data, please consider citing the data as
follows:

Sonnet, Luke. 2019. “2018 Pakistani General Election Polling Station
Data.”
<a href="https://doi.org/10.17605/osf.io/mtsnd" class="uri">https://doi.org/10.17605/osf.io/mtsnd</a>.

**Available datasets:**

-   Polling station wide data (~200MB, [.csv in OSF
    repository](https://osf.io/69gpn/download,%20%5Bdocumentation%5D)
    -   Each row is a polling station
    -   All released for provincial and national assemblies
    -   Multiple columns with candidate returns and polling station
        meta-data
    -   This contains data from:
        -   ECP form 28 (e.g. registered voter totals)
        -   ECP form 48 (e.g. candidate-level returns, total turnout)
        -   ECP form 45 (e.g. unofficial gender-based turnout)
-   Polling station long data (~230MB, [.csv in OSF
    repository](https://osf.io/2sdzg/download), \[documentation\])
    -   Each row is a polling station-candidate
    -   Omits some polling station level data to save on space (can
        merge with the wide data if desired)
-   Electoral area (census block) data (~80MB, [.csv in OSF
    repository](https://osf.io/kmfh6/download), \[documentation\])
    -   Each row is a census block-polling station
    -   Allows matching census blocks to polling stations

We thank the [United States Institute of Peace](https://www.usip.org/)
for funding this data collection and
[RCons](https://www.rcons.org/rconsnew/) for executing the data entry
with professionalism.
