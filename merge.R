

```{r}
f45_merge <- f45_clean %>%
  select(-assembly_type) %>%
  rename_all(list(~gsub("total_", "ps_total_", .))) %>%
  rename(comments_form45 = comments,
         ps_total_votes_form45 = ps_total_votes) %>%
  # fix one probable mistake (ps id not
  # found in form 28s)
  mutate(
    ps_id = ifelse(
      constituency_id == "NA21" & ps_name == "GOVT. ELEMENTARY PRIMARY SCHOOL, SHAMILAT (P) COMBINED",
      903,
      ps_id
    ),
    constituency_ps_id = paste0(constituency_id, "_", ps_id)
  )


# Merge in form 45 data
names(f28n)
ea_level_45 <- bind_rows(
  f28n %>% mutate(assembly = "National"), 
  f28p %>% 
    mutate(assembly = "Provincial") %>%
    select(-assembly_type)
) %>%
  rename(ea_name_urban = name_ea_urban,
         ea_name_rural = name_ea_rural,
         ea_voter_serial_numbers = no_voters_on_ea) %>%
  rename_at(vars(starts_with("male"), starts_with("female"), starts_with("total")), list(~paste0("ea_", .))) %>%
  mutate(constituency_ps_id = paste0(constituency_id, "_", ps_id),
         ea_id = paste0(constituency_ps_id, "_", block_code)) %>%
  left_join(f45_merge) 

# Check that all f45 data is recovered
setdiff(f45_merge$constituency_ps_id, ea_level_45$constituency_ps_id)

# Quite a few electoral areas not merged
length(setdiff(ea_level_45$constituency_ps_id, f45_merge$constituency_ps_id))

f48_merge <- f48 %>% 
  rename_at(vars(starts_with("registered_"), starts_with("total_number_")), list(~paste0("constituency_", .))) %>%
  rename_at(vars(starts_with("can_votes")), list(~gsub("can_votes", "can_psvotes", .))) %>%
  rename(comments_form48 = comments) %>%
  rename_at(vars(ends_with("votes")), list(~paste0("ps_", .))) %>%
  rename(ps_total_votes_form48 = ps_total_votes) %>%
  mutate(constituency_ps_id = paste0(constituency_id, "_", ps_id)) %>%
  select(-constituency_no_NA)

# Now merge all results
ea_level_all <- ea_level_45 %>% left_join(f48_merge)

# Check all form 48s were merged in 
setdiff(f48_merge$constituency_ps_id, ea_level_all$constituency_ps_id)
# Some missing form 48s
setdiff(ea_level_all$constituency_ps_id, f48_merge$constituency_ps_id)
# Many missing constituencies
setdiff(ea_level_all$constituency_id, f48_merge$constituency_id)

head(f49)

wide_can_dat <- f49 %>% 
  select(constituency_id, candidate_id, party_affiliation, valid_votes_polled) %>%
  gather(key, val, -constituency_id, -candidate_id) %>%
  mutate(candidate_id = ifelse(key == "party_affiliation",
                               paste0("can_party_", candidate_id),
                               paste0("can_constituencyvotes_", candidate_id))) %>%
  select(-key) %>%
  spread(candidate_id, val)



alldat <- ea_level_all %>% 
  select(-assembly_type) %>%
  left_join(wide_can_dat)
```

# Create PS-level data

```{r}
psdat <- 
  ```

```{r}
consdat <- wide_can_dat  

```
table(alldat$constituency_area)
alldat %>%
  group_by(constituency_ps_id) %>%
  filter(length(unique(constituency_area)) > 1) %>%
  select(1:5) %>%
  as.data.frame
alldat %>%
  group_by(constituency_ps_id) %>%
  filter(length(unique(ps_name)) > 1) %>%
  select(1:5) %>%
  as.data.frame

alldat %>%
  group_by(constituency_ps_id) %>%
  filter(length(unique(constituency_no_NA)) > 1) %>%
  select(1:5, constituency_no_NA) %>%
  as.data.frame

```

# Merge

```{r}
alldat_filled <- alldat %>%
  select(-starts_with("constituency_total")) %>%
  group_by(constituency_ps_id) %>%
  # fill in missing values from above merges
  mutate_at(
    vars(
      starts_with("ps_total"), 
      ps_valid_votes,
      ps_invalid_votes,
      starts_with("comments"),
      constituency_name,
      contains("constituencyvotes"),
      starts_with("constituency_registered"),
    ),
    list(~ifelse(all(is.na(.)), NA, setdiff(., NA)))
  )

psdat <- alldat_filled %>%
  summarize_at(
    vars(
      -starts_with("ea"), 
      -starts_with("block_code"),
      -starts_with("constituency_area"), 
      -ps_name,
      -constituency_no_NA,
      -ps_id_NA
    ),
    unique
  )
```

# Data checks

```{r}
# Sum of psvotes = ps_valid_votes
can_vote_check <- alldat %>%
  select(contains("_psvotes_"), ps_valid_votes, constituency_ps_id) %>%
  gather(can, votes, contains("_psvotes_")) %>%
  group_by(constituency_ps_id) %>%
  #summarize(n_valid = length(unique(ps_valid_votes))) %>%
  #filter(n_valid > 1)
  summarize(total_can_votes = sum(votes, na.rm = TRUE),
            ps_valid_votes = ifelse(all(is.na(ps_valid_votes)), NA, setdiff(unique(ps_valid_votes), NA)))

ggplot(can_vote_check, aes(x = total_can_votes, y = ps_valid_votes)) + 
  geom_point()
```

```{r}

head(alldat)
names(alldat)

# Merge in candidate data
head(f49) %>% as.data.frame

table(is.na(f45_clean_dat$male_turnout_share))
hist(f45_clean_dat$male_turnout_share)
hist(f45_clean_dat$female_turnout_share)

f45_clean_dat %>%
  group_by()

f45_clean_dat %>% 
  filter(male_turnout_share < 1 & female_turnout_share < 1) %>%
  ggplot(., aes(x = male_turnout_share, y = female_turnout_share)) +
  geom_point(alpha = 0.1, shape = 1) +
  geom_abline(slope = 1, intercept = 0) +
  facet_wrap(~province) +
  theme_bw()
f45_clean_dat %>% arrange(-male_turnout_share) %>% as.data.frame
f45_clean_dat %>% arrange(-female_turnout_share) %>% as.data.frame

with(f45_clean_dat)

head(f48) %>% select(1:14) %>% as.data.frame
head(f28n) %>% as.data.frame

intersect(names(f28n), names(f45_clean))

with(f45, table(total_turnout == total_votes))
filter(f45, total_turnout != total_votes) %>% as.data.frame
head(f45) %>% as.data.frame
```

```{r, include = FALSE}
f45_clean <- f45 %>%
  mutate_if(is.numeric, list(~ifelse(. < 0, NA, .)))

f28_clean <- bind_rows(f28n, f28p) %>%
  group_by(constituency_id, ps_id) %>%
  mutate_at(
    vars(male_voters, female_voters, total_voters),
    list(~ifelse(. < 0, NA, .))
  ) %>%
  summarize_at(
    vars(male_voters, female_voters, total_voters),
    list(~sum(.))
  )

f45_clean_dat <- f45_clean %>%
  left_join(f28_clean) %>%
  mutate(male_turnout_share = total_male_turnout / male_voters,
         female_turnout_share = total_female_turnout / female_voters)

write_csv(f45_clean_dat, path = "f45_merged.csv")
```