##-- QUESTION 1

#- Lookup table
library(dplyr)  

cty = read_csv('Local_Authority_District_to_County_(December_2024)_Lookup_in_EN.csv')  
rgn = read_csv('Local_Authority_District_to_Region_(December_2024)_Lookup_in_EN.csv')  
cty  
rgn  
lookup_table = cty %>%  
    left_join(rgn, by = 'LAD24CD') %>%  
  select(LAD24CD,CTY24CD, CTY24NM, RGN24CD, RGN24NM) 
lookup_table 


#- Augementing the data set
imd_group = read_csv("imd2025_group.csv")  
imd_group  
aug_imd = imd_group %>%  
  left_join(lookup_table, by = c("LAD24CD" = "CTY24CD")) %>% 
  mutate(Region = coalesce(Region, RGN24NM)) %>%  
  distinct()  

write_csv(aug_imd,"Augmented_DataSet.csv")  

sum(is.na(aug_imd$RGN24NM))  
names(imd_group)  
names(lookup_table) 

#- Building the summary table
region_summary = aug_imd %>%  
  group_by(Region) %>%  
  summarise(n_districts = n()) %>%  
  arrange(Region)  
region_summary  


#- Scatter matrix
library(GGally)  
domains = new_table %>%  
  select(Income, Employment, Education, Health, Crime, Barriers, Living)  
ggpairs(domains) 


###################################################################


##-- QUESTION 2

#- New North and South dataset
north_south = read_csv("Augmented_DataSet_north_south.csv") 


#- Boxplots for the seven domains
ggplot(north_south, aes(x = Region, y = Education, fill = Region)) + 
  geom_boxplot(alpha = 0.7) +  
  labs(title = "Education Deprivation by Region", y = "Education Score",   x = "") +  
  theme_minimal() +  
  theme(legend.position = "none")  


ggplot(north_south, aes(x = Region, y =Income, fill = Region)) + 
  geom_boxplot(alpha = 0.7) +  
  labs(title = "Income Deprivation by Region", y = "Income Score", x = "") +  
  theme_minimal() +  
  theme(legend.position = "none")  


ggplot(north_south, aes(x = Region, y = Employment, fill = Region)) + 
  geom_boxplot(alpha = 0.7) +  
  labs(title = "Employment Deprivation by Region", y = "Employment Score", x = "") +  
  theme_minimal() +  
  theme(legend.position = "none")  


ggplot(north_south, aes(x = Region, y = Health, fill = Region)) + 
  geom_boxplot(alpha = 0.7) +  
  labs(title = "Health Deprivation by Region", y = "Health Score", x = "") +  
  theme_minimal() +  
  theme(legend.position = "none")  


ggplot(north_south, aes(x = Region, y = Crime, fill = Region)) + 
  geom_boxplot(alpha = 0.7) +  
  labs(title = "Crime Deprivation by Region", y = "Crime Score", x = "") +  
  theme_minimal() +  
  theme(legend.position = "none")  



ggplot(north_south, aes(x = Region, y = Barriers, fill = Region)) + 
  geom_boxplot(alpha = 0.7) +  
  labs(title = "Barriers Deprivation by Region", y = "Barriers Score", x = "") +  
  theme_minimal() +  
  theme(legend.position = "none")  


ggplot(north_south, aes(x = Region, y =Living, fill = Region)) + 
  geom_boxplot(alpha = 0.7) +  
  labs(title = "Living Deprivation by Region", y = "Living Score", x = "") +  
  theme_minimal() +  
  theme(legend.position = "none") 


#- Finding the districts of the outliers
health_stats = north_south %>%  
  group_by(Region) %>%  
  summarise(  
    Q1 = quantile(Health, 0.25),  
    Q3 = quantile(Health, 0.75),  
    IQR = Q3 - Q1)  

health_outliers = north_south %>%  
  left_join(health_stats, by = "Region") %>%  
  filter(Health < (Q1 - 1.5*IQR) | Health > (Q3 + 1.5*IQR)) %>% 
  select(Region, Health)  
health_outliers 

education_stats = north_south %>%  
  group_by(Region) %>%  
  summarise(  
    Q1 = quantile(Education, 0.25),  
    Q3 = quantile(Education, 0.75), 
    IQR = Q3 - Q1)  

education_outliers = north_south %>% 
  left_join(education_stats, by = "Region") %>%  
  filter(Education < (Q1 - 1.5*IQR) | Education > (Q3 + 1.5*IQR)) %>% 
  select(Region, Education)  
education_outliers 


###################################################################
 
##-- QUESTION 3


imd_scaled <- scale(imd_domains) 
pca_full <- prcomp(imd_scaled, center = TRUE, scale. = TRUE) 

cat("\nPCA scree plot...\n") 
print(fviz_eig(pca_full, addlabels = TRUE)) 


cat("\nPCA variable loadings plot...\n") 
print(fviz_pca_var(pca_full, repel = TRUE)) 

cat("\nPCA biplot PC1 vs PC2 coloured by Region...\n") 
print(fviz_pca_biplot(pca_full, geom.ind = "point", habillage = imd_aug$Region, repel = TRUE)) 

cat("\nPCA biplot PC2 vs PC3 coloured by Region...\n") 
print(fviz_pca_biplot(pca_full, axes = c(2,3), geom.ind = "point", habillage = imd_aug$Region, repel = TRUE)) 


PCA London onlyimd_london <- imd_aug %>% filter(Region == "London")if (nrow(imd_london) > 3) {  pca_london <- prcomp(scale(imd_london %>% select(all_of(domain_vars))), center = TRUE, scale. = TRUE)  cat("\nLondon PCA scree plot...\n")  print(fviz_eig(pca_london, addlabels = TRUE))  cat("\nLondon PCA variable plot...\n")  print(fviz_pca_var(pca_london, repel = TRUE))} else {  cat("\nLondon subset too small for stable PCA.\n")}  




###################################################################

##-- QUESTION 4

# Load necessary libraries 
library(tidyverse) 
library(olsrr) 
library(ggfortify) 
library(factoextra) 
library(cluster) 
library(GGally) 
library(sf) 


#- 4a
compute_ac_table = function(X, 
                             dist_methods = c("euclidean", "manhattan"), 
                             link_methods = c("single", "complete", "average", "ward")) { 
  tbl = expand.grid(distance = dist_methods, 
                     linkage = link_methods, 
                     stringsAsFactors = FALSE) %>% 
    as_tibble() %>% 
    mutate(agglomerative_coefficient = NA_real_) 
  
  for (i in seq_len(nrow(tbl))) { 
    d = dist(X, method = tbl$distance[i]) 
    ag = agnes(d, method = tbl$linkage[i]) 
    tbl$agglomerative_coefficient[i] <- ag$ac 
    } 
  tbl %>% arrange(desc(agglomerative_coefficient)) 
  } 


cat("\n=============================\n") 
cat("4(a) Cluster districts (ROWS)\n") 
cat("=============================\n") 

district_ac_table <- compute_ac_table(imd_domains) 

cat("\nSmall comparison table (Top 8 methods by agglomerative coefficient):\n") 
print(district_ac_table %>% slice(1:8)) 

best_rows <- district_ac_table %>% slice(1) 
cat("\nChosen method for district dendrogram (highest AC):\n") 
print(best_rows) 

d_rows <- dist(imd_domains, method = best_rows$distance[1]) 
ag_rows <- agnes(d_rows, method = best_rows$linkage[1]) 

cat("\nDistrict dendrogram plotting now...\n") 
plot(ag_rows, which.plots = 2, 
     main = paste0("District Dendrogram: ", best_rows$linkage[1], " + ", best_rows$distance[1])) 



#- 4b 
cat("4(b) Cluster domains (COLUMNS)\n") 
cat("=============================\n") 

X_domains <- t(as.matrix(imd_domains)) 
domain_ac_table <- compute_ac_table(X_domains) 

cat("\nSmall comparison table (Top 8 methods by agglomerative coefficient):\n") 
print(domain_ac_table %>% slice(1:8)) 

best_cols <- domain_ac_table %>% slice(1) 
cat("\nChosen method for domain dendrogram (highest AC):\n") 
print(best_cols) 


d_cols <- dist(X_domains, method = best_cols$distance[1]) 
ag_cols <- agnes(d_cols, method = best_cols$linkage[1]) 

cat("\nDomain dendrogram plotting now...\n") 
plot(ag_cols, which.plots = 2, 
     main = paste0("Domain Dendrogram: ", best_cols$linkage[1], " + ", best_cols$distance[1])) 


###################################################################


##-- QUESTION 5

library(sf)
library(dplyr)
library(ggplot2)

districts = st_read("Local_Authority_Districts_December_2024_Boundaries_UK_BFC_4880322208219286849")
imd = read.csv("imd2025_group.csv")
names(imd)

map_data = districts %>%
  left_join(imd, by = "LAD24CD")
map_data

ggplot(map_data) +
  geom_sf(aes(fill = Overall), colour = NA) + 
  scale_fill_viridis_c(option = "plasma", direction = -1,
                       name = "Overall IMD") +
  labs(
    title = "Choropleth Map representing Overall IMD (2025)",
    subtitle = "District level variation across the UK",
    caption = "Data: IMD 2025 & ONS District Boundaries") +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold", size = 16),
    axis.text = element_blank(),
    axis.title = element_blank(),
    panel.grid = element_blank())
map_data