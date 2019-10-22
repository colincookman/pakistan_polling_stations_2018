
# 2018 Pakistani General Election Polling Station Data

This repository hosts links to and documentation for several detailed datasets regarding the 2018 General Elections in Pakistan. These data were released by the Election Commission of Pakistan, largely in scanned PDFs and incomplete in their coverage. They have been manually entered by a team of data entry operators and somewhat cleaned to improve their ease of use for researchers, journalists, policy makers, and others. 

There are bound to be some errors in these data. Please report them by filing an issue above or sending [Luke Sonnet](lukesonnet.com) an email.

All the data is held in an accompanying Open Science Framework repository. If you use the data, please consider citing the data as follows:

Sonnet, Luke. 2019. “2018 Pakistani General Election Polling Station Data.” https://doi.org/10.17605/osf.io/mtsnd.

**Available datasets:**

* Polling station wide data (~200MB, [.csv in OSF repository](https://osf.io/69gpn/download), [documentation](https://raw.githack.com/colincookman/pakistan_polling_stations_2018/master/codebooks/ps_wide_data_codebook.html))
  * Each row is a polling station
  * All released for provincial and national assemblies
  * Multiple columns with candidate returns and polling station meta-data
  * This contains data from:
    * ECP form 28 (e.g. registered voter totals), ([original links](https://www.ecp.gov.pk/frmGenericPage.aspx?PageID=3155), [backup](https://drive.google.com/drive/folders/129J6KaqN2J6wLu-ABjJUnPRAOwl0Ixrm))
    * ECP form 48 (e.g. candidate-level returns, total turnout), ([original links](https://www.ecp.gov.pk/frmGenericPage.aspx?PageID=3223), [backup](https://drive.google.com/drive/folders/1mO-Wz6PvEA0QojpQm_4J9FNg0pkBKmEl))
    * ECP form 45 (e.g. unofficial gender-based turnout), ([original links](https://www.ecp.gov.pk/frmGenericPage.aspx?PageID=3223), [backup](https://drive.google.com/drive/folders/1mO-Wz6PvEA0QojpQm_4J9FNg0pkBKmEl))
* Polling station long data (~230MB, [.csv in OSF repository](https://osf.io/2sdzg/download), [documentation](https://raw.githack.com/colincookman/pakistan_polling_stations_2018/master/codebooks/ps_long_data_codebook.html))
  * Each row is a polling station-candidate
  * Omits some polling station level data to save on space (can merge with the wide data if desired)
* Electoral area (census block) data (~80MB, [.csv in OSF repository](https://osf.io/kmfh6/download), [documentation](https://raw.githack.com/colincookman/pakistan_polling_stations_2018/master/codebooks/electoral_area_codebook.html))
  * Mostly from ECP form 28, linked above
  * Each row is a census block-polling station
  * Allows matching census blocks to polling stations

We thank the [United States Institute of Peace](https://www.usip.org/) for funding this data collection and [RCons](https://www.rcons.org/rconsnew/) for executing the data entry with professionalism.
