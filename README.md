# NBA-Playoff-Predictor
As we are now entering the NBA playoffs, I wanted to create a program that can help me have a better grasp on what teams will win and what teams with lose using probabilities. If I can predict winning teams, it makes it easier to bet on each game and potentially have a better idea on which games will be close and which games could be blow outs.

-   Predicting games is obviously a tricky thing to do since if it was easy, everyone would do it.

Like with any sport, basketball has thousands of stats that can be used to incorporate a teams likely hood of success and failure.

-   Home or Away
-   Injuries
-   Losing Streaks
-   Opponent Strategy
-   Off Games

I needed to find a simple yet comprehensive way to cover all of my bases.

# Getting Started

[This is what the data for each team looks like raw.](https://www.espn.com/nba/team/schedule/_/name/bos/seasontype/2)

I wanted to get the match data from each team and give them home stats and away stats since that is an important factor in deciding games, escpecially in the playoffs.

## Accuracy

Testing on regular season game data for 2023 Season, I made an error on 269/1104 games, or 24.36%

 ![image](https://github.com/Willharrison1/NBA-Playoff-Predictor/assets/169865680/b05d79ed-ceb0-45a3-85fd-f54ce5a6d8cd)

## Playoff Prediction

Typing each team into home and away, it allows you to get a sense of how likely each team is to win at each location.

-  p0 is win chance for away and p1 is win chance for home.

![image](https://github.com/Willharrison1/NBA-Playoff-Predictor/assets/169865680/3c5f2f13-a9e0-4b42-a591-7ffe0d9e1afd)

Taking the highest average win-chance between home and away results in a conference finals looking as below.

![image](https://github.com/Willharrison1/NBA-Playoff-Predictor/assets/169865680/707f2964-53a7-4e6c-81ab-e0cea815457b)

Boston handles the Knicks with relative ease, and the Thunder slightly edge out the TimberWolves.

![image](https://github.com/Willharrison1/NBA-Playoff-Predictor/assets/169865680/962b4b6f-b774-4287-b461-e25365984a66)

And a Finals that looks like this with the winner being Boston over OKC.



# Conclusions

## Steps forward

I would love to incorporate some new aspects to this model such as:
-   elo rating for teams
-   incorporate more player stats
-   injury reports
-   live changes

## Things I wish I did differently

-   This project might have served as a better medium in python since I know other uses and it has more documentation in this field.
-   I also wish I had a stronger understanding of h2o before I tried this project, I just really wanted to present on this topic.
-   Sadly, I didn't have time to fully analyze the current playoffs since this model takes a long time for increased projections.
