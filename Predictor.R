#Packages Needed
pacman::p_load(tidyverse, tidymodels, dplyr, gt, ggplot2, tidyr, rvest, lubridate, stringr, h2o, zoo, )

teams = c("tor", "mil", "den", "gs", "ind", "phi", "okc", "por", "bos", "hou", "lac", "sa",
          "lal", "utah", "mia", "sac", "min", "bkn", "dal", "no", "cha", "mem", "det", "orl",
          "wsh", "atl", "phx", "ny", "chi", "cle")

teams_fullname = c("Toronto", "Milwaukee", "Denver", "Golden State", "Indiana", "Philadelphia", "Oklahoma City","Portland", "Boston", "Houston", "LA", "San Antonio", "Los Angeles", "Utah", "Miami", "Sacramento", "Minnesota", "Brooklyn", "Dallas", "New Orleans", "Charlotte", "Memphis", "Detroit", "Orlando", "Washington", "Atlanta", "Phoenix", "New York", "Chicago", "Cleveland")

by_team = {} # this initializes an empty data frame to store scrapped data below
for (i in 1:length(teams)) {
  url = paste0("http://www.espn.com/nba/team/schedule/_/name/", teams[i], "/seasontype/2")
  #constructed each teams url from the above format
  webpage = read_html(url) #scrapes the page for data
  team_table = html_nodes(webpage, 'table')
  team_c = html_table(team_table, fill = TRUE, header = TRUE)[[1]] #converts the HTML table into a data frame using the `html_table()` function
  # Add team abbreviation and full name to the dataframe
  team_c$URLTeam = toupper(teams[i])
  team_c$FullURLTeam = teams_fullname[i]
  # These two lines add two new columns to the data
  # Combine dataframes
  by_team = rbind(by_team, team_c)
}

# Rename columns by column number
current_names = colnames(by_team)
new_names = c("DATE", "OPPONENT", "RESULT", "W-L", "Hi Points", "Hi Rebounds", "Hi Assists","Random","URLTeam","FullURLTeam")
by_team = setNames(by_team, new_names)
#Remove Random column since it is NA
by_team = select(by_team, -Random)


by_team_mod = by_team |> 
  select(-(`Hi Points`:`Hi Assists`)) |> #Hide these two columns
  mutate( #Change away the @ and vs. Clean up the OPPONENT column
    CleanOpponent = str_replace(str_extract(str_replace(OPPONENT, "^vs", ""), "[A-Za-z].+"), " \\*", ""), # `"[A-Za-z].+"), " \\*", ""` are patterns that come in the str_extract and str_replace functions for changes
    HomeAway = ifelse(substr(OPPONENT, 1, 2) == "vs", "Home", "Away"),
    WL = `W-L`) |> 
  separate(WL, c("W", "L"), sep = "-") |> 
  mutate( #calculate the winning percentage
    Tpct = as.numeric(W) / (as.numeric(L) + as.numeric(W)),
    dummy = 1,
    Outcome = ifelse(substr(RESULT, 1, 1) == "W", 1, 0)) |> # win = 1 loss = 0
  group_by(URLTeam) |> 
  mutate(
    Rank = row_number(),# add rank to show the games played value
    TeamMatchID = paste0(Rank, URLTeam, HomeAway),
    #Code Below calculate the win % of last 10 games.
    TLast10 = rollapplyr(Outcome, 10, sum, partial = TRUE) / rollapplyr(dummy, 10, sum, partial = TRUE)) |> 
  group_by(URLTeam, HomeAway) |> 
  mutate(
    Rpct = cumsum(Outcome) / cumsum(dummy), # Cumulative Win Percentage and of last 10 the row below
    RLast10 = rollapplyr(Outcome, 10, sum, partial = TRUE) / rollapplyr(dummy, 10, sum, partial = TRUE)) |> 
  group_by(URLTeam) |> 
  na.omit() |> 
  select(TeamMatchID, Rank, DATE, URLTeam, FullURLTeam, CleanOpponent, HomeAway, Tpct, TLast10, Rpct, RLast10, Outcome) # select desired columns

df2023 = data.frame(matrix(ncol = 16, nrow = 0))# Create a df for the year with below columns
x = c(colnames(by_team_mod), "HRpct", "HRLast10",  "ARpct", "ARLast10")
colnames(df2023) = x


for (i in 1:nrow(by_team_mod)) {
  if(by_team_mod[i,"HomeAway"]=="Home") { # Checks if it is a home game
    df2023[i,c(1:14)]=data.frame(by_team_mod[i,c(1:12)], by_team_mod[i,c(10:11)])
  }#Creates a data frame consisting of columns 1 to 12 and columns 10 to 11 of the current row in by_team_mod, representing the team's performance and the opponent's performance in the last 10 games.
  else {
    df2023[i,c(1:12)]=by_team_mod[i,c(1:12)]
    df2023[i,c(15:16)]=by_team_mod[i,c(10:11)]
  }# df2023[i, c(1:12)]: Assigns values to the first 12 columns of the df2023 data frame. df2023[i, c(15:16)]: Assigns values to columns 15 and 16 of the df2023 data frame. by_team_mod[i, c(10:11)]: Selects columns 10 to 11 of the current row in by_team_mod, representing the team's performance and the opponent's performance in the last 10 games.
}

# fill the NA values with the previous ones, group by team
df2023 = df2023 |> group_by(URLTeam) |> fill(HRpct , HRLast10, ARpct,  ARLast10, .direction=c("down"))|>ungroup()|>na.omit()|>filter(Rank>=10) # Only wanted to look at above 10 games
# create the home df
H_df2023 = df2023 |> filter(HomeAway=="Home")|>ungroup()# Make home games have H_
colnames(H_df2023)=paste0("H_", names(H_df2023))


# create the away df
A_df2023 = df2023 |> filter(HomeAway!="Home")|>ungroup()# Make away games have A_
colnames(A_df2023)=paste0("A_", names(A_df2023))

# perform an inner join between the H_df2023 (home team) and A_df2023 (away team) data frames based on two matching conditions: "H_CleanOpponent" matching "A_FullURLTeam" and "H_DATE" matching "A_DATE"
Full_df2023 = H_df2023 |> inner_join(A_df2023, by=c("H_CleanOpponent"="A_FullURLTeam", "H_DATE"="A_DATE"))|>
  select(H_DATE, H_URLTeam, A_URLTeam, H_Tpct, H_TLast10, H_HRpct, H_HRLast10, H_ARpct, H_ARLast10, 
         A_Tpct, A_TLast10, A_HRpct, A_HRLast10, A_ARpct, A_ARLast10,  H_Outcome)
# Build the model
h2o.init()#this function is necessary to begin h2o in R
Train_h2o = as.h2o(Full_df2023) # converts FUll_df2023 into a h2o frame

Train_h2o$H_Outcome = as.factor(Train_h2o$H_Outcome) #Makes the H_outcome(Win/Loss) a factor variable

# random forest model
model2023 = h2o.randomForest(y = 16, x = c(4:15), training_frame = Train_h2o, max_depth = 5)
# y = 16 represents the amount of columns in the data frame, x = c(4:15) is where I want the model to look
#max_depth = 5. Specifies the maximum depth of the trees in the random forest. This parameter controls the complexity of the model and helps prevent over fitting. I mostly chose this value based on feel of the results and tweaked it according to my prior knowledge on what the percentages at the end should look like to an extent.

h2o.performance(model2023)# computes metrics
# create an empty data frame and fill it in order to get the summary statistics

df2023 = data.frame(matrix(ncol = 16, nrow = 0))
x = c(colnames(by_team_mod), "HRpct", "HRLast10",  "ARpct", "ARLast10")
colnames(df2023) = x

for (i in 1:nrow(by_team_mod)) {
  if(by_team_mod[i,"HomeAway"]=="Home") {
    df2023[i,c(1:14)]=data.frame(by_team_mod[i,c(1:12)], by_team_mod[i,c(10:11)])
  }
  else {
    df2023[i,c(1:12)]=by_team_mod[i,c(1:12)]
    df2023[i,c(15:16)]=by_team_mod[i,c(10:11)]
  }
}#if statement checks whether the "HomeAway" column for the current row is "Home". 
#If the condition is met, it assigns values from specific columns of the current row of by_team_mod to corresponding columns in df2023. 
#If the condition is not met (i.e., the team is not playing at home), it assigns values to the appropriate columns in df2023.
#The purpose is to rearrange and combine the columns of by_team_mod into df2023 based on whether the team is playing at home or away.

# fill the NA values with the previous ones group by team
m_df2023 = df2023 |> group_by(URLTeam) |> fill(HRpct , HRLast10, ARpct,  ARLast10, .direction=c("down")) |> ungroup() |> na.omit() |> group_by(URLTeam) |> slice(n()) |> ungroup()
### Make predictions

df2023={}
h = c("CLE","BOS","IND","NY","DAL","OKC","DEN","MIN")
a = c("BOS","CLE","NY","IND","OKC","DAL","MIN","DEN")

for (i in 1:length(a)) {
  th = m_df2023 |> filter(URLTeam==h[i])|>select(Tpct:ARLast10, -Outcome)
  colnames(th) = paste0("H_", colnames(th))
  
  ta = m_df2023|>filter(URLTeam==a[i])|>select(Tpct:ARLast10, -Outcome)
  colnames(ta)=paste0("A_", colnames(ta))
  pred_data=cbind(th,ta)
  tmp=data.frame(Away=a[i], Home=h[i],as.data.frame(predict(model2023,as.h2o(pred_data))))
  df2023=rbind(df2023, tmp)
}
df2023 = df2023|>select(-predict)
df2023
