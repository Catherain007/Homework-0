##########################################################
# Create edx set, validation set (final hold-out test set)
##########################################################
#Install the pacman package
if(!require(pacman)) install.packages("pacman", repos = "http://cran.us.r-project.org")
#Load the required libraries
#If a package below is missing, p_load will automatically download it from CRAN
pacman::p_load(tidyverse, ggplot2, ggthemes, data.table, lubridate, caret, 
               knitr, scales, treemapify)
#All Data for the MovieLens Dataset Will be obtained from the following sources:
# https://grouplens.org/datasets/movielens/10m/
# http://files.grouplens.org/datasets/movielens/ml-10m.zip
#Data Preparation
#Download File

library(lubridate)
library(data.table)
library(corrplot)
library(corrr)
library(tinytex)




### Download MovieLens 10M dataset:
### https://grouplens.org/datasets/movielens/10m/
### http://files.grouplens.org/datasets/movielens/ml-10m.zip

dl <- tempfile()
download.file("http://files.grouplens.org/datasets/movielens/ml-10m.zip", dl)

ratings <- fread(text = gsub("::", "\t", readLines(unzip(dl, "ml-10M100K/ratings.dat"))),
                 col.names = c("userId", "movieId", "rating", "timestamp"))

movies <- str_split_fixed(readLines(unzip(dl, "ml-10M100K/movies.dat")), "\\::", 3)
colnames(movies) <- c("movieId", "title", "genres")


### if using R 4.0 or later:
movies <- as.data.frame(movies) %>% mutate(movieId = as.numeric(movieId),
title = as.character(title),
genres = as.character(genres))


movielens <- left_join(ratings, movies, by = "movieId")


### Validation set will be 10% of MovieLens data


set.seed(1, sample.kind = "Rounding" ) # if using R 3.5 or earlier, use `set.seed(1)`
test_index <- createDataPartition(y = movielens$rating, times = 1, p = 0.1, list = FALSE)
edx <- movielens[-test_index,]
temp <- movielens[test_index,]


### Make sure userId and movieId in validation set are also in edx set
validation <- temp %>% 
  semi_join(edx, by = "movieId") %>%
  semi_join(edx, by = "userId")

### Add rows removed from validation set back into edx set
removed <- anti_join(temp, validation)
edx <- rbind(edx, removed)

#### remove uncessary file for better processing time
rm(dl, ratings, movies, test_index, temp, movielens, removed)

##############Exploratory Data Analysis#########

#### Check missing values in any column.

sapply(edx, {function(x) any(is.na(x))}) %>% knitr::kable()

####To get dimension of data matrix 

dim(edx)

#####To get a better idea of the distribution of variables in the dataset,

summary(edx)


 ##### Data Visualizations and Analysis
 
avge_rating <- mean(edx$rating) # calculate overall average rating of whole edx data set
medi_rating <- median(edx$rating) # calculate median rating of whole edx data set

######RATING

  edx_ratings <- edx %>% # take data from edx and. assign new data set.. 
  group_by(rating) %>% # ...group data by rating and... 
  summarize(num_ratings = n()) %>% # ...summarize frequency of each rating and... 
  arrange(desc(num_ratings)) # ...arrange data in descending order

edx_ratings # display rating frequencies
edx_ratings %>% # take data and..... 
  ggplot(aes(rating, num_ratings)) + # scatter plot rating vs frequency ........and
  geom_point(aes(size = num_ratings)) + #  display rating point size with number of ratings.......and.
    scale_size_continuous(limits = c(0, 7e+06)) + # set the scale in Y........and 
  xlim(0,5) + # set the scale in x....and
  labs(x = "Rating", y = "Total Ratings", title = "Total by Rating")
            # puting the lables 


#####USER
                
edx %>%  # finding unique userId in data set 
  
  summarize(num_users = n_distinct(userId))

edx_users <- edx %>% # take data from edx and. assign new data set.. 
  group_by(userId) %>% # ...group by user and... 
  summarize(num_ratings = n(), avg_rating = mean(rating)) %>% # ...summarize ratings counts and average rating and... 
  arrange(desc(num_ratings)) # ...arrange data in descending order


edx_users %>% # take data from edx and... 
    ggplot(aes(userId, num_ratings, col = avg_rating)) + #scatter plot userId vs rating frequency ...and
   geom_point() +  # display average rating of user by colour scale 
   labs(title="Number of rating by userId")

edx_users %>%
  ggplot(aes(x = userId, y = num_ratings, color = avg_rating)) +  # Scatter plot with userId and number of ratings, colored by average rating
  geom_point(size = 3, alpha = 0.6) +  # Adjust size and transparency for visibility
  scale_color_gradientn(colours = rainbow(6)) +  # Apply a color gradient to represent average rating
  labs(
    title = "Number of Ratings by UserId",  # Main title
    x = "UserId",  # Label for the x-axis
    y = "Number of Ratings",  # Label for the y-axis
    color = "Average Rating"  # Color legend title
  ) +
  theme_minimal() +  # Apply minimal theme for a clean look
  theme(
    plot.title = element_text(size = 16, face = "bold", color = "darkblue", hjust = 0.5),  # Title styling
    axis.text.x = element_text(size = 10, angle = 45, hjust = 1, color = "darkred"),  # Rotate x-axis labels and style them
    axis.text.y = element_text(size = 12, color = "darkgreen"),  # Style y-axis labels
    panel.grid.major = element_line(color = "gray", size = 0.3),  # Grid lines for the plot
    panel.grid.minor = element_blank()  # Remove minor grid lines for a cleaner appearance
  )

library(dplyr)
library(ggplot2)
edx_users %>%
  # Summarize the total number of ratings per userId
  group_by(userId) %>%
  summarize(total_ratings = sum(num_ratings)) %>%
  # Calculate the proportion for pie chart
  mutate(proportion = total_ratings / sum(total_ratings)) %>%
  ggplot(aes(x = "", y = proportion, fill = factor(userId))) +  # Create the pie chart with proportion
  geom_bar(stat = "identity", width = 1) +  # Bar plot to create the pie sections
  coord_polar(theta = "y") +  # Use polar coordinates to make it circular (pie chart)
  labs(
    title = "Distribution of Ratings by UserId",  # Main title
    fill = "UserId"  # Legend label for UserId
  ) +
  theme_void() +  # Remove background and axis for clean pie chart look
  theme(
    plot.title = element_text(size = 16, face = "bold", color = "darkblue", hjust = 0.5)  # Title styling
  )
top_10users<-head(edx_users,10) # assign data to new data set

lowest_10users<-tail( edx_users,10) # assign data to new data set

plot(top_10users) # correlation plot for top 10 user

 plot(lowest_10users) # correlation plot for buttom 10 user



####MOVIE 

 
 edx %>% # finding unique movieId in data set 
  summarize( n_movies = n_distinct(movieId))

edx_films <- edx %>% # take data and assign new data set and... 
  group_by(movieId) %>% # ...group by movie and... 
  summarize(num_ratings = n(), avg_rating = mean(rating)) %>% # ...summarize ratings counts and average rating and... 
  arrange(desc(num_ratings)) # ...arrange data in descending order


edx_films %>% 
  ggplot(aes(x = movieId, y = num_ratings, color = avg_rating)) +  # Plot movieId vs number of ratings with color by average rating
  geom_point(size = 3, alpha = 0.6) +  # Add points with adjusted size and transparency for better visualization
  scale_color_gradientn(colours = terrain.colors(55)) +  # Apply a 5-color terrain gradient for better color differentiation
  labs(
    x = "Movie ID",  # Label for the x-axis
    y = "Number of Ratings",  # Label for the y-axis
    title = "Ratings by Movie ID",  # Title of the plot
    color = "Average Rating"  # Label for the color legend
  ) +
  theme_light() +  # Apply a light theme for a clean and modern look
  theme(
    plot.title = element_text(size = 18, face = "bold", color = "darkblue", hjust = 0.5),  # Title styling with bold and centered alignment
    axis.text.x = element_text(size = 10, angle = 45, hjust = 1, color = "darkred"),  # Rotate x-axis labels and adjust their style
    axis.text.y = element_text(size = 12, color = "darkgreen"),  # Style y-axis labels
    panel.grid.major = element_line(color = "gray", size = 0.5),  # Major grid lines with gray color
    panel.grid.minor = element_blank()  # Remove minor grid lines for a cleaner look
  )



####plot with unique movie 

edx_films %>%
  mutate(row_number = 1:n()) %>%  # Create a unique identifier for each movie using row numbers
  ggplot(aes(x = row_number, y = num_ratings, color = avg_rating)) +  # Scatter plot: row number (movie ID) vs. number of ratings
  geom_point(size = 3, alpha = 0.7) +  # Points with size adjustment and slight transparency
  scale_color_gradientn(colours = terrain.colors(7)) +  # Apply a color gradient based on average ratings
  labs(
    x = "Movie ID",  # X-axis label
    y = "Total Ratings",  # Y-axis label
    title = "Distribution of Ratings Across Movies",  # Main plot title
    color = "Average Movie Rating"  # Color legend label
  ) +
  theme_light() +  # Light theme for a clean, modern look
  theme(
    plot.title = element_text(size = 18, face = "bold", color = "navy", hjust = 0.5),  # Bold title with centered alignment
    axis.text.x = element_text(size = 10, angle = 45, hjust = 1, color = "darkorange"),  # Rotated X-axis labels with adjusted size
    axis.text.y = element_text(size = 12, color = "darkgreen"),  # Styled Y-axis labels with custom size and color
    panel.grid.major = element_line(color = "gray80", size = 0.3),  # Lighter gray for major grid lines
    panel.grid.minor = element_blank(),  # Remove minor grid lines for a cleaner appearance
    plot.margin = margin(20, 20, 20, 20)  # Increase plot margins for better readability
  )

 
# the data frame top_title contains the top 10 movies which count the major number of ratings
top_title <- edx %>% # take the data .....and
  group_by(title) %>% # group by movie title .....and
  summarize(count=n()) %>% # ...summarize ratings counts ...and 
  top_n(10,count) %>% # take top 10 rating numbers..and
  arrange(desc(count)) # arrange data in decent order

#Horizontal bar chart of top_20 title of  movies 


top_title %>%  # Take the data for movie titles and rating counts
  ggplot(aes(x = reorder(title, count), y = count)) +  # Reorder the titles based on the count of ratings
  geom_bar(stat = "identity", fill = "#FF6347", color = "black", width = 0.7) +  # Create a bar plot with a tomato color and black borders
  coord_flip(ylim = c(0, 40000)) +  # Flip the coordinates and set the y-axis range
  geom_text(aes(label = count), hjust = -0.1, size = 3.5, color = "black") +  # Add rating counts with better spacing and color
  labs(
    title = "Top 10 Movies Based on Number of Ratings",  # Add a modernized title
    x = NULL,  # Remove the x-axis label for cleaner presentation
    y = "Number of Ratings"  # Add y-axis label
  ) +
  theme_minimal() +  # Use a minimalistic theme
  theme(
    plot.title = element_text(size = 16, face = "bold", hjust = 0.5, color = "darkblue"),  # Customize the title
    axis.text.x = element_text(angle = 45, hjust = 1, color = "darkgreen"),  # Rotate x-axis labels and customize color
    axis.text.y = element_text(color = "darkred"),  # Customize y-axis label color
    panel.grid.major = element_line(color = "gray", size = 0.5, linetype = "dashed"),  # Add a dashed grid for a modern touch
    panel.grid.minor = element_blank()  # Remove minor grid lines
  )
###GENRES


edxgenres<-edx%>% # take data from edx and assign new data set
  group_by(genres) %>% # ...group data by genre and... 
  summarize(num_ratings = n(), avg_rating = mean(rating)) %>% # ...summarize ratings counts and average rating and... 
  arrange(desc(num_ratings)) # ...arrange data in descending order

head(edxgenres,10) # show top 10 rating genere

top_10g<-head(edxgenres,10)  # assign top genere data to new data set


tail(edxgenres,10) # show lowest 10 rating genere



top_10g %>%  # Take the data for top 10 genres
  ggplot(aes(x = genres, y = num_ratings, color = avg_rating)) +  # Scatter plot between genres and number of ratings, with color based on average rating
  geom_point(size = 7) +  # Plot the points with a size of 4 for visibility
  scale_colour_gradientn(colours = rainbow(7)) +  # Set the color gradient to a rainbow color palette
  labs(x = "Genre", y = "Number of Ratings", title = "Ratings by Genre") +  # Add labels for x, y, and title
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1, color = "darkred", size = 10),  # Rotate x-axis labels to 45 degrees, change color to darkred, and adjust size
    plot.title = element_text(hjust = 0.5, color = "darkblue", size = 14, face = "bold"),  # Center the title and customize its appearance
    plot.subtitle = element_text(hjust = 0.5, color = "green", size = 12),  # Center subtitle and change its color
    panel.background = element_rect(fill = "darkgray"),  # Set the panel background to light gray
    panel.grid.major = element_line(size = 0.5, linetype = "solid", color = "gray"),  # Major grid lines in solid gray
    panel.grid.minor = element_line(size = 0.25, linetype = "dotted", color = "lightgray")  # Minor grid lines in dotted light gray
  )



#An error bar plots for genres with more than 100000 ratings


edx %>% 
  group_by(genres) %>%  # Group the data by genres
  summarize(n = n(), 
            avg_rating = mean(rating), 
            se = sd(rating) / sqrt(n())) %>%  # Calculate the number of ratings, average rating, and standard error
  filter(n >= 100000) %>%  # Filter genres with ratings greater than or equal to 100,000
  mutate(genres = reorder(genres, avg_rating)) %>%  # Reorder genres by average rating
  ggplot(aes(x = genres, y = avg_rating, ymin = avg_rating - 2 * se, ymax = avg_rating + 2 * se)) + 
  geom_point(color = "darkblue") +  # Plot the genres vs. average rating with points
  geom_errorbar(width = 0.7, color = "red") +  # Add error bars to represent the standard error
  theme(axis.text.x = element_text(angle = 45, hjust = 1, color = "darkgreen", size = 10)) +  # Rotate x-axis labels and customize appearance
  labs(title = "Error Bar Plots by Genres", subtitle = "Average Ratings with Standard Error") +  # Set the title and subtitle
  theme(  # Set a custom background and grid style
    panel.background = element_rect(fill = "skyblue", color = "darkred", size = 1),
    panel.grid.major = element_line(size = 0.9, linetype = "dotted", color = "green"),
    panel.grid.minor = element_line(size = 0.9, linetype = "dotted", color = "yellow"),
    plot.title = element_text(hjust = 0.5, color = "darkblue", size = 14, face = "bold"),  # Center and customize title
    plot.subtitle = element_text(hjust = 0.5, color = "purple", size = 12)  # Center and customize subtitle
  )

##### TIME 

#ggplot showing timestamp per date(week unit)

  edx %>% 
    mutate(date = round_date(as_datetime(timestamp), unit = "week")) %>%  # Add a new 'date' column with rounded dates
    group_by(date) %>%  # Group by the 'date' column
    summarize(avg_rating = mean(rating)) %>%  # Calculate the average rating for each week
    ggplot(aes(x = date, y = avg_rating)) + 
    geom_line(color = "blue") +  # Line plot for the average rating over time
    geom_point(color = "red") +  # Add red points on the line for each data point
    ggtitle("Timestamp, Time Unit: Week") +  # Add a main title
    labs(subtitle = "Average Ratings") +  # Add a subtitle
    theme_minimal()  # Apply a minimal theme for better aesthetics
#### Preprocessing ####

##### Finding the effect/ bias 

####Over all mean  

  mue <- mean(edx$rating)
mue


#####User effect (e_u) determine bias for each user (mean rating of the user compare to overall mean)

user_avgs <- edx %>% # take data from the edx. and assign as new data set.....
  group_by(userId) %>%  # make group by userID.....and 
  summarise(e_u = mean(rating) - mue) # summarize result of user effect...

#### User bias/effect plots

EU_hist <- user_avgs %>%  #assign user avgerate rating to new data set....and
    ggplot(aes(e_u)) +    # plot user bias histrogram vs user count......
  geom_histogram(color = "blue", fill="gray", bins=40) + #select bin size and fill color
  ggtitle("User Effect Distribution Histogram") +
  xlab("User Bias") +
  ylab("User Count")  # put all labels 
 
plot(EU_hist) # plot the histogram data of bias

####movie effect (e_i) determine bias for each movie (mean rating of the movie compare to overall mean)

movie_avgs <- edx %>% # take data from edx....and assign new data set
  group_by(movieId) %>% # group by movieId..and 
  summarise(e_i = mean(rating) - mue) # summarize result of movie effect...

#### Movie bias/effect plots

EM_hist <- movie_avgs %>% #assign data to new data set....and
  ggplot(aes(e_i)) +  #plot movie bias histrogram vs movie count......
  geom_histogram(color = "blue", fill="gray",bins=40) + #select bin size and fill color
  ggtitle("Movie Effect Distribution Histogram") +
  xlab("Movie Bias") +
  ylab("Movie Count") # put all labels 
  
plot(EM_hist) # plot the histogram data of bias

#### Time effect (e_g) determine bias for each genres group (mean rating of the genre compare to overall mean)
gene_avgs <- edx %>% # Take  data from edx....and assign new data set
  group_by(genres) %>% # Group by (genres)
  summarise(e_g = mean(rating) - mue) # summarize result of genres effect...


##### Genre bias/effect plots

EG_hist <- gene_avgs %>%  #assign data to new data set
  ggplot(aes(e_g)) + #plot genre bias histrogram vs genres count......
  geom_histogram(color = "blue", fill="gray",bins=40) + #select bin size and fill color
  ggtitle("Genres Effect Distribution Histogram") +
  xlab("Genres Bias") +
  ylab("Genres Count") # put all labels 

plot(EG_hist) # plot the histogram data of bias



##### Time effect (e_t) determine bias for each rate time by week (mean rating of the time compare to overall mean)

## put additional column name date in edx data set 

edx <- edx %>% mutate(date = round_date(as_datetime(timestamp), unit = "week")) 

time_avgs <- edx %>% #assign data to new data set
  group_by(date) %>%  # group by date 
  summarise (e_t = mean(rating) - mue ) # summarize result of time effect...

# Time effect/ bias plot 

ET_hist <- time_avgs %>% #assign data to new data set
  ggplot(aes(e_t)) + #plot timebias histrogram vs time count.....
  geom_histogram(color = "blue", fill="gray",bins=40) + #select bin size and fill color
  ggtitle("Time Effect Distribution Histogram") +
  xlab("Time Bias") +
  ylab("Time Count") + ggtitle("Timestamp, time unit : week") # put all labels 
  

plot(ET_hist) # plot the histogram data of bias

##### Add user bias column to edx and assign new data set for additional coulumns

edx_bias <- edx  %>% left_join(movie_avgs, by='movieId')%>% #left join movie bias data to edx and assign new data set 
  left_join(user_avgs, by='userId')%>% #left join user bias data to edx and assign new data set 
    left_join(gene_avgs,'genres')%>% #left join gene bias data to edx and assign new data set 
  left_join(time_avgs,'date') #left join time bias data to edx and assign new data set 

##### select bias/effect columns for more exploration

edxbias<-edx_bias  %>% select(userId,rating,e_i,e_u,e_g,e_t) # assign new data set and select bias values for new analysis

head(edxbias) # print top six row of data set to check no required value missing

###### Add additional column for correlation analysis

edxbiasall<- edxbias%>% mutate(moviebias=mue+e_i) %>% #assign new data set and put new moviebias column
  mutate(userbias=mue+e_u) %>% #assign new data set and put new userbias column
  mutate(genresbias=mue+e_g) %>% #assign new data set and put new genres bias colum
  mutate(timebias=mue+e_t) %>% #assign new data set and put new timebias column
  mutate (use_mov_bs=mue+e_u+e_i) %>% #assign new data set and put new user moviebias column
  mutate (use_mov_ge_bs= mue+e_u+e_i+e_g) #assign new data set and put new user movie genres bias column


### Install required packages

install.packages("corrplot")
library(corrplot)
install.packages("corrr")
library(corrr)

### Correlation check for dependent variable and combine independent variables
library(tidyverse)
corr <- edxbiasall %>% select(rating, moviebias,userbias,genresbias,timebias,use_mov_bs,use_mov_ge_bs)
index <- sample(1:nrow(corr), 1000000)
corr <- corr[index, ]

corrplot(cor(corr), method = "number", type="upper")

###Check correlation value between dependent and independent variables and themself

y<- (edxbiasall$rating)
x<- (edxbiasall$use_mov_bs)
x1<- (edxbiasall$use_mov_ge_bs)

cor(y,x)
cor(y,x1)
cor(x,x1)


######RMSE (residual mean square error) 

RMSE <- function(true_ratings, predicted_ratings){
  sqrt(mean((true_ratings - predicted_ratings)^2))
}

#### Made data partation for test and train  from edx set for regularization
library(caret)
set.seed(1, sample.kind="Rounding") # if using R 3.5 or earlier, use `set.seed(1)`
test_index <- createDataPartition(y = edx$rating, times = 1, p = 0.1, list = FALSE)
train <- edx[-test_index,]
temp <- edx[test_index,]

### Make sure userId and movieId in test set are also in train set
test <- temp %>% 
  semi_join(train, by = "movieId") %>%
  semi_join(train, by = "userId")

### Add rows removed from test set back into train set
removed <- anti_join(temp, test)
train <- rbind(train, removed)
rm(temp,removed,test_index)

#### Regularization of movie + user effect model ##

### Finding optimum parameter in edx 

lambdas <- seq(0, 10, 0.25)

#### below code will take several minutes to run

rmses <- sapply(lambdas, function(l){
  muu <- mean(train$rating)
  b_i <- train %>%
    group_by(movieId) %>%
    summarise(b_i = sum(rating - muu)/(n()+l))
  b_u <- train %>%
    left_join(b_i, by="movieId") %>%
    group_by(userId) %>%
    summarise(b_u = sum(rating - b_i - muu)/(n()+l))
  predicted_ratings <- test %>%
    left_join(b_i, by = "movieId") %>%
    left_join(b_u, by = "userId") %>%
    mutate(pred = muu + b_i + b_u) %>%
    .$pred
  
  return(RMSE(predicted_ratings,test$rating))
})

### plot lambda and RMSEs to select optimal Theda


L<-qplot(lambdas, rmses,geom=c("point"))  # assign qplot for lambda and rmses
L+labs(title = "Tuning for Rmses vs lambdas ") # add the main title for plot

### find optimal lambda (optimun parameter)

lambda <- lambdas[which.min(rmses)] # assign theta value which give minimun rmse value
lambda # print minumun lambda value for rsme



#####TEST all MODELS####
####Put new column of date in validation set
  
  validation <- validation %>% mutate(date = round_date(as_datetime(timestamp), unit = "week"))

### predict all unknown ratings mu with validation rating

mue<-mean(edx$rating)

naive_rmse <- RMSE(validation$rating, mue) # assign rmse value 


### create a table to store results of prediction approaches

rmse_results <- tibble(Method = "The Average", RMSE = naive_rmse) # put result to rmse table and put the name of result

####### Test and save RMSE results with time effect


predicted_ratings <- validation %>% # assign predicted rating  and...
  left_join(time_avgs, by="date") %>% # left join time avgs by date to validation set....
  mutate(pred = mue + e_t) %>% # put new column of predition 
  .$pred # take predit value

model_2_rmse <- RMSE(predicted_ratings, validation$rating) # assign rmse value 
rmse_results <- bind_rows(rmse_results,                    # put  result to the rmse result table
                          tibble(Method="Time Effect Model", # put the name of rmse results
                                 RMSE = model_2_rmse))

########
##Test and save RMSE results with gene effect

predicted_ratings <- validation %>%  # assign predicted rating  and...
  left_join(gene_avgs, by="genres") %>%   # left join genre avgs by date to validation set....
  mutate(pred = mue + e_g) %>%  # put new column of predition 
  .$pred  # take predit value
model_3_rmse <- RMSE(predicted_ratings, validation$rating) # assign rmse value 
rmse_results <- bind_rows(rmse_results,                     # put  result to the rmse result table
                          tibble(Method="Genres Effect Model",  # put the name of rmse result
                                 RMSE = model_3_rmse))    

####### Test and save RMSE results with user effect

predicted_ratings <- validation %>% #assign predicted rating  and..
  left_join(user_avgs, by="userId") %>% # left join user avgs by date to validation set....
  mutate(pred = mue + e_u) %>%  # put new column of predition 
  .$pred # take predit value
model_4_rmse <- RMSE(predicted_ratings, validation$rating) # assign rmse value 
rmse_results <- bind_rows(rmse_results, # put  result to the rmse result table
                          tibble(Method="User Effect Model",
                                 RMSE = model_4_rmse)) # put the name of rmse result




### Test and save RMSE results with movie effect

predicted_ratings <- validation %>% # assign predicted rating  and..
  left_join(movie_avgs, by='movieId') %>% # left join movie avgs by date to validation set....
  mutate(pred = mue + e_i ) %>% # put new column of predition 
  .$pred # take predit value
model_5_rmse <- RMSE(predicted_ratings, validation$rating) # assign rmse value 
rmse_results <- bind_rows(rmse_results,    # put  result to the rmse result table
                          tibble(Method="Movie Effect Model",
                                 RMSE = model_5_rmse)) # put the name of rmse result




### test and save new RMSE results with user&movie effect


predicted_ratings <- validation %>% #assign predicted rating  and..
  left_join(movie_avgs, by='movieId') %>% # left join movie avgs by date to validation set....
  left_join(user_avgs, by='userId') %>% # left join user avgs by date to validation set....
  mutate(pred = mue + e_i + e_u) %>% # put new column of predition 
  .$pred # take predit value
model_6_rmse <- RMSE(predicted_ratings, validation$rating) # assign rmse value 
rmse_results <- bind_rows(rmse_results,   # put  result to the rmse result table
                          tibble(Method = "Combine Movie and User Effects Model",
                                 RMSE = model_6_rmse)) # put the name of rmse result


### test and save new RMSE results with regularize user&movie effect with tuning parameter (lambda)

lambda <- 5
mue <- mean(edx$rating)
movie_reg_avgs <- edx %>%
  group_by(movieId) %>%
  summarize(e_i = sum(rating - mue)/(n()+lambda)) 

user_reg_avgs <- edx %>% 
  left_join(movie_reg_avgs, by="movieId") %>%
  group_by(userId) %>%
  summarize(e_u = sum(rating - mue-e_i)/(n()+lambda))

predicted_ratings <- validation %>% #assign predicted rating  and..
  left_join(movie_reg_avgs, by='movieId') %>% # left join movie avgs by date to validation set....
  left_join(user_reg_avgs, by='userId') %>% # left join user avgs by date to validation set....
  mutate(pred = mue + e_i + e_u) %>% # put new column of predition 
  .$pred # take predit value

model_7_rmse  <- RMSE(predicted_ratings, validation$rating)

rmse_results <- bind_rows(rmse_results, # assign rmse value and put  result to the rmse result table
                          tibble(Method = "Regularized combine Movie and User Effects Model",
                                 RMSE = model_7_rmse)) # put the name of rmse result

### table showing all model final test results

rmse_results %>% knitr::kable()

###### Packages additional installed for R mark down PDF
install.packages("tinytex") # install tinytes
tinytex:::is_tinytex()      # check installed or not
devtools::install_github('yihui/tinytex')   # install dev tools
options(tinytex.verbose = TRUE)  # use tunytex verbose option
