library(tidyverse)

ps_import <- read.csv("./data/ps_data.csv", stringsAsFactors = FALSE)
ps_data <- ps_import
ps_data$ps_number.1 <- NULL

ps_data$cons_type[ps_data$cons_type == "PA"] <- "Provincial Assembly"
ps_data$cons_type[is.na(ps_data$cons_type)] <- "National Assembly"

# convert province numbers to province names
ps_data$prov_number[ps_data$prov_number == "9"] <- "KPK"
ps_data$prov_number[ps_data$prov_number == "10"] <- "FATA"
ps_data$prov_number[ps_data$prov_number == "11"] <- "Punjab"
ps_data$prov_number[ps_data$prov_number == "12"] <- "Sindh"
ps_data$prov_number[ps_data$prov_number == "13"] <- "Balochistan"
ps_data$prov_number[ps_data$prov_number == "14"] <- "Islamabad"

# concatenate standard constituency numbers
ps_data <- ps_data %>% mutate(
  constituency_number = paste(ps_data$cons_type, ps_data$cons_number, sep = "-")
)

ps_data$constituency_number[ps_data$prov_number == "KPK" & ps_data$cons_type == "Provincial Assembly"] <- 
  gsub("Provincial Assembly-", "PK-", ps_data$constituency_number[ps_data$prov_number == "KPK" & ps_data$cons_type == "Provincial Assembly"])

ps_data$constituency_number[ps_data$prov_number == "Punjab" & ps_data$cons_type == "Provincial Assembly"] <- 
  gsub("Provincial Assembly-", "PP-", ps_data$constituency_number[ps_data$prov_number == "Punjab" & ps_data$cons_type == "Provincial Assembly"])

ps_data$constituency_number[ps_data$prov_number == "Sindh" & ps_data$cons_type == "Provincial Assembly"] <- 
  gsub("Provincial Assembly-", "PS-", ps_data$constituency_number[ps_data$prov_number == "Sindh" & ps_data$cons_type == "Provincial Assembly"])

ps_data$constituency_number[ps_data$prov_number == "Balochistan" & ps_data$cons_type == "Provincial Assembly"] <- 
  gsub("Provincial Assembly-", "PB-", ps_data$constituency_number[ps_data$prov_number == "Balochistan" & ps_data$cons_type == "Provincial Assembly"])

ps_data$constituency_number[ps_data$cons_type == "National Assembly"] <- 
  gsub("National Assembly-", "NA-", ps_data$constituency_number[ps_data$cons_type == "National Assembly"])

# add a polling station code
ps_data <- ps_data %>% mutate(
  ps_code = paste(ps_data$constituency_number, ps_data$ps_number, sep = "-")
)

# sum_errors <- ps_data %>% filter((male_votes + female_voters) != total_votes)
# no sum errors found

# categorize GIS errors
ps_data$GIS_Errors <- NA
ps_data$GIS_Errors[ps_data$lat < 24 | ps_data$long < 60] <- "Lat-Lon Error"
ps_data$GIS_Errors[ps_data$lat == "" | ps_data$long == ""] <- "No GIS Data Reported"

ps_data <- ps_data %>% mutate(
  lat_lon = paste(ps_data$lat, ps_data$long, sep = ", ")
)
ps_data$lat_lon[ps_data$lat_lon == ", "] <- NA

# categorize PS type by PS booths
ps_data$ps_type <- "Mixed PS"
ps_data$ps_type[ps_data$male_booths == 0] <- "Female PS"
ps_data$ps_type[ps_data$female_booths == 0] <- "Male PS"
ps_data$ps_type[ps_data$total_booths == 0] <- "Mixed PS"

# identify possible errors in voter booths
ps_data$booth_errors <- NA
ps_data$booth_errors[ps_data$male_votes >0 & ps_data$male_booths == 0] <- "Male Voters No Male Booths"
ps_data$booth_errors[ps_data$female_voters >0 & ps_data$female_booths == 0] <- "Female Voters No Female Booths"
ps_data$booth_errors[ps_data$total_booths == 0] <- "No Booths Reported"

# rearrange and rename variables

names(ps_data) <- c("province", "constituency_number", "assembly", "ps_number", "ps_name", "male_booths", "female_booths", "total_booths", "male_voter_reg", "female_voter_reg",
                    "total_voter_reg", "lat", "long", "constituency_code", "ps_code", "GIS_errors", "lat_long", "ps_type", "booth_errors")

ps_data <- dplyr::select(ps_data,
                         assembly, province, constituency_code, constituency_number, ps_code, ps_number, ps_type, ps_name, male_booths, female_booths, total_booths,
                         male_voter_reg, female_voter_reg, total_voter_reg, lat, long, lat_long, GIS_errors, booth_errors)

ps_data <- dplyr::arrange(ps_data, assembly, province, constituency_number, ps_number)

# identify missing polling stations in sequence

missing_ps <- ps_data %>%
  group_by(assembly, province, constituency_code) %>%
  summarize(missing_ps_number = list(setdiff(seq_len(max(ps_number)), ps_number))) %>% 
  unnest() %>%
  mutate(ps_code = paste0(constituency_code, "-", missing_ps_number))

write.csv(missing_ps, "ps_sequence_gaps.csv", row.names = FALSE)


# identify unique polling stations by coordinates

# remove GIS errors
unique_PS <- ps_data %>% filter(is.na(GIS_errors))
# just the instance for each ps instance by lat/lon
unique_PS <- unique_PS[!duplicated(unique_PS$lat_long), 1:19]

write.csv(unique_PS, "unique_PS_coords.csv", row.names = FALSE)

# summary statistics
province_summary <- ps_data %>% group_by(assembly, province) %>%
  summarize(
    total_male_reg = sum(male_voter_reg),
    total_female_reg = sum(female_voter_reg),
    total_voter_reg = sum(total_voter_reg)
  )

write.csv(province_summary, "province_voter_reg.csv", row.names = FALSE)

constituency_summary <- ps_data %>% group_by(assembly, province, constituency_code) %>%
  summarize(
    total_male_reg = sum(male_voter_reg),
    total_female_reg = sum(female_voter_reg),
    total_voter_reg = sum(total_voter_reg)
  )

write.csv(constituency_summary, "constituency_voter_reg.csv", row.names = FALSE)

write.csv(ps_data, "pk_polling_stations_2018.csv", row.names = FALSE)
