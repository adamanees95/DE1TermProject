# DE1TermProject
This repository is for the Data Engineering-1 Term Project


### DATA:
1. political_parties.csv: This file contains all the political parties that are registered with the Election Commission of Pakistan (ECP). A party ID was generated for analysis.
2. NA_Candidates.csv: This file contains all the candidates who registered themselves as constestants for a seat in the National Assembly of Pakistan (NA). Candidate ID was generated for analysis.
3. NA_Results.csv: This file contains the results of all the candidates who contested in the elections.
4. NA_Winners.csv: THis file contains the list of winners of National Assembly (NA) seats

#### SOURCE: https://www.kaggle.com/zusmani/predict-pakistan-elections-2018

#### SCHEMA INFORMATION:
Schema: pakelections2018
Tables:
1. political_parties
2. NA_Candidates
3. NAResults2018
3. NAWinners

Relationship(s)
1. NA_Candidates and political_parties are linked using the party_id
2. NA_Winners and NA_Candidates are linked using the cand_id

### OPERATIONAL LAYER: 
~~~~
### CREATION OF SCHEMA TO BEGIN THE OPERATION LAYER ###
DROP SCHEMA IF EXISTS pakelections;
CREATE SCHEMA pakelections;

-- default schema for further operations -- 
USE pakelections;
~~~~
CREATE TABLES:
~~~~
-- Create table 'political_parties' --
DROP TABLE IF EXISTS political_parties;
CREATE table political_parties(
		party_id INT PRIMARY KEY,
		party_name VARCHAR(255),
        party_acronym VARCHAR(52));
        
-- Create table 'NA_Candidates' --
DROP TABLE IF EXISTS NA_candidates;
CREATE table NA_candidates(
		cand_id INT PRIMARY KEY,
        cand_name VARCHAR(255),
        party_id INT,
        party_acronym VARCHAR(52),
        province VARCHAR(52),
        FOREIGN KEY(party_id) REFERENCES pakelections.political_parties(party_id));
        
-- Create table 'NAWinners' --
DROP TABLE IF EXISTS NAWinners;
CREATE TABLE NAWinners(
		result_id int PRIMARY KEY,
        district VARCHAR(52),
        constituency VARCHAR(52), 
        cand_id INT,
        party_id INT,
        acronym VARCHAR(52),
        votes INT,
        total_valid INT,
        total_rejected INT,
        total_votes INT,
        total_registered INT,
        turnout FLOAT,
        FOREIGN KEY(cand_id) REFERENCES pakelections.NA_candidates(cand_id));

-- Create table 'NAResults' --
DROP TABLE IF EXISTS NAResults2018;
CREATE table NAResults2018(
		s_no INT PRIMARY KEY,
        district VARCHAR(52),
        seat VARCHAR(52),
        constituency VARCHAR(52),
        cand_id INT,
        party_id INT,
        acronym VARCHAR(52),
        votes INT,
        FOREIGN KEY(cand_id) REFERENCES pakelections.na_candidates(cand_id));
~~~~
LOAD DATA:
~~~~
-- Political Parties --
LOAD DATA LOCAL INFILE 'Users/MAdamAnees/Desktop/sqlprojectadvanced/political_parties.csv' 
INTO TABLE political_parties
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n' 
IGNORE 1 LINES 
(party_id,party_name,party_acronym);

-- NA Candidates -- 
LOAD DATA LOCAL INFILE 'Users/MAdamAnees/Desktop/sqlprojectadvanced/NA_candidates.csv'
INTO TABLE NA_candidates
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(cand_id, cand_name, party_id, party_acronym, province);

-- NA Winners -- 
LOAD DATA LOCAL INFILE 'Users/MAdamAnees/Desktop/sqlprojectadvanced/NAWinners.csv' 
INTO TABLE NAWinners
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n' 
IGNORE 1 LINES 
(result_id, district, constituency,cand_id, party_id, acronym, votes, total_valid, total_rejected, total_votes, total_registered, turnout)
;

-- NA Results -- 
LOAD DATA LOCAL INFILE 'Users/MAdamAnees/Desktop/sqlprojectadvanced/NAResults.csv' 
INTO TABLE NAResults2018
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(s_no,district,seat,constituency,cand_id,party_id,acronym, votes);

~~~~

### SCHEMA STRUCTURE:


## ANALYTICAL LAYER 

Here, we have created a datawarehouse where all the information from the perspective of constituency will be available. This includes information about where the constituency exists, the number of that constituency, the candidate who won from that constituency, the number of votes that are registered in that constituency, the number of votes that were cast, and the number of votes that were rejected. It will also provide information on the number of votes received by the individual who won that constituency. Lastly, it will tell the turnout percentage using the information available regarding the votes casted and votes that are registered.

## QUESTIONS TO ANSWER:

~~~~
1. The Party that won the most seats in the elections of 2018?
~~~~

~~~~
2. Voting Statistics: Total Number of Registered Votes, Total Number of Votes Casted, Total Number of Votes Rejected, Voter Turnout Percentage,
~~~~

~~~~
3. Party Popularity: Which party was the most popular one in the elections of 2018?
~~~~

~~~~
4. Election Results by Province: Which Party was the most successful in each province?
~~~~

~~~~
5. Which Candidate won the most number of seats?
~~~~

~~~~
6. Provincial Statistics: Most number of votes registered, most number of votes casted, most number of votes registered, largest turnout?
~~~~

### ETL PROCEDURE: 
As explained above, the analytical layer will be produced using the multiple tables and columns to have one denormalized structure that will then be used for analysis. 

#### Constituency - Consolidated Data:
~~~~
DROP PROCEDURE IF EXISTS constituency_consolidated;

DELIMITER $$

CREATE PROCEDURE constituency_consolidated()
BEGIN

DROP TABLE IF EXISTS constituency_2018;
CREATE TABLE constituency_2018
SELECT 
 nawinners.constituency,
 nawinners.cand_id,
 na_candidates.cand_name,
 nawinners.party_id,
 nawinners.acronym AS party,
 nawinners.votes AS winner_votes,
 nawinners.total_votes,
 nawinners.total_valid,
 nawinners.total_rejected,
 nawinners.total_registered,
 nawinners.turnout -- remove turnout
 FROM na_candidates
INNER JOIN nawinners
USING(cand_id);

END$$

DELIMITER ;

CALL constituency_consolidated();

~~~~

### DATA MARTS --- VIEWS FOR ANALYSIS:

#### PARTY WITH MOST NUMBER OF SEATS:
~~~~
-- ######### Total seats won #####
DROP VIEW IF EXISTS most_seats_won;

CREATE VIEW `most_seats_won` AS
SELECT
	party,
	COUNT(party) AS 'Total Seats Won'
FROM constituency_2018
GROUP BY party
ORDER BY COUNT(party) DESC;
    
SELECT * FROM most_seats_won;
~~~~
#### VOTING STATISTICS BY CONSTITUENCY:
~~~~
DROP VIEW IF EXISTS voting_data;

CREATE VIEW `Voting_data` AS
SELECT
	constituency,
    total_votes,
    total_valid,
    total_rejected,
    ROUND((total_votes/total_registered)*100,2) AS 'Voter Turnout %'
FROM constituency_2018;
    
SELECT * FROM voting_data;
~~~~
#### POPULAR VOTE - MOST POPULAR PARTY BY VOTES:
~~~~
-- ##### PARTY POPULARITY #####
DROP VIEW IF EXISTS party_popularity;

CREATE VIEW `party_popularity` AS
SELECT
	party,
    SUM(total_valid) AS 'Total Votes'
FROM constituency_2018
GROUP BY party
ORDER BY SUM(total_valid) DESC;

SELECT * FROM party_popularity;
~~~~
#### ELECTION RESULTS BY PROVINCE:
~~~~
~~~~
#### MOST SUCCESSFUL CANDIDATE: CANDIDATE WITH MOST NUMBER OF SEATS:
~~~~
~~~~
####
