# Polling station data and GIS locations for Pakistan's 2018 elections

This repository hosts an open dataset in a tidy .csv format of 69,753 polling stations released on July 23 2018 by the Election Commission of Pakistan for the Pakistani general elections for the [national](https://www.ecp.gov.pk/frmGISPublishGE.aspx?type=NA) and [provincial assemblies](https://www.ecp.gov.pk/frmGISPublishGE.aspx?type=PA), including voter registration data and GIS coordinates. 

Code used to download the data from the ECP website is forthcoming as of this initial commit; the file ps_data.csv in the data folder is the product of this initial scrape. The code 01_ps_data_cleanup.R was subsequently used to clean and tidy the initial data scrape to produce the final output, pk_polling_stations_2018.csv.

Please note that this code is still a work in progress and data outputs hosted here may be incomplete. For questions, suggestions, or to contribute, please leave an issue here or contact the contributors, Luke Sonnet and Colin Cookman.

# Data gaps
The ECP release of GIS data for polling stations does not appear to be fully complete; ps_sequence_gaps.csv identifies 8308 polling station numbers missing from the available sequence, grouped by constituency. In addition to this, 3688 polling stations did not report GIS data despite being include in the GIS dataset, and 16 reported erroneous latitude / longitude coordinates located outside of Pakistan.

In 25 cases, male and female voters were listed as being registered despite the absence of a male/female voter booth, and in 13 cases, no booths were reported at all despite reported voter registration figures. Although we cannot currently ascertain the direction of the error, polling stations are currently classified by type by their booth composition (all-male, all-female, or mixed).

# Plans for expansion
Although we have not yet conducted detailed analysis to confirm co-location in all cases, the unique latitude/longitude coordinates for each polling station should allow for determining the parent/child relationship for all national assembly and provincial assembly constituencies. (A voter should cast votes for both national and provincial assembly elections at the same single polling station.) As a preliminary step, we have identified all unique latitude / longitude coordinates reported within the dataset, selecting the first observation in each case where there are duplicates.

The ECP [previously released polling station plans in pdf format](https://www.ecp.gov.pk/frmGenericPage.aspx?PageID=3155), which may offer an opportunity to identify missing polling stations not in the GIS dataset. The pdf polling station plan also includes census block codes associated with each polling station, which are not included in the machine-readable data here. Once joined with [2017 census data](https://github.com/colincookman/pakistan_census), that would allow for more granular data on the percentage of the population registered to vote.

Should the ECP release polling-station level results following the elections on July 25 2018, vote patterns can also be mapped below the constituency level. The use of other geographic data or satellite imagery may offer additional opportunities for analysis.