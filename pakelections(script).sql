## OPERATIONAL LAYER ##

### CREATION OF SCHEMA TO BEGIN THE OPERATION LAYER ###
DROP SCHEMA IF EXISTS pakelections;
CREATE SCHEMA pakelections;

-- default schema for further operations -- 
USE pakelections;

DROP TABLE IF EXISTS political_parties;
CREATE table political_parties(
		party_id INT PRIMARY KEY,
		party_name VARCHAR(255),
        party_acronym VARCHAR(52));

LOAD DATA LOCAL INFILE 'Users/MAdamAnees/Desktop/sqlprojectadvanced/political_parties.csv' 
INTO TABLE political_parties
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n' 
IGNORE 1 LINES 
(party_id,party_name,party_acronym);

-- Create table 'NA_Candidates' --
DROP TABLE IF EXISTS NA_candidates;
CREATE table NA_candidates(
		cand_id INT PRIMARY KEY,
        cand_name VARCHAR(255),
        party_id INT,
        party_acronym VARCHAR(52),
        province VARCHAR(52),
        FOREIGN KEY(party_id) REFERENCES pakelections.political_parties(party_id));

LOAD DATA LOCAL INFILE 'Users/MAdamAnees/Desktop/sqlprojectadvanced/NA_candidates.csv'
INTO TABLE NA_candidates
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(cand_id, cand_name, party_id, party_acronym, province);
     
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
        
LOAD DATA LOCAL INFILE 'Users/MAdamAnees/Desktop/sqlprojectadvanced/NAWinners.csv' 
INTO TABLE NAWinners
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n' 
IGNORE 1 LINES 
(result_id, district, constituency,cand_id, party_id, acronym, votes, total_valid, total_rejected, total_votes, total_registered, turnout)
;

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
        
LOAD DATA LOCAL INFILE 'Users/MAdamAnees/Desktop/sqlprojectadvanced/NAResults.csv' 
INTO TABLE NAResults2018
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(s_no,district,seat,constituency,cand_id,party_id,acronym, votes);


## ANALYTICAL LAYER ##

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

-- VIEWS ---

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

-- ####### AVG VOTING DATA ######

DROP VIEW IF EXISTS voting;

CREATE VIEW `Voting_data` AS
SELECT
	constituency,
    total_votes,
    total_valid,
    total_rejected,
    ROUND((total_votes/total_registered)*100,2) AS 'Voter Turnout %'
FROM constituency_2018;
    
SELECT * FROM voting_data;

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

-- Trigger(s) --

DROP TABLE IF EXISTS election_info_history;

CREATE TABLE election_info_history(
 constituency VARCHAR(10) PRIMARY KEY,
 cand_id INT,
 cand_name VARCHAR(255),
 party_id INT,
 party VARCHAR(255),
 winner_votes INT,
 total_votes INT,
 total_valid INT,
 total_rejected INT,
 total_registered INT);
 
DROP TABLE IF EXISTS trigger_history;

CREATE TABLE trigger_history(
    id INT PRIMARY KEY AUTO_INCREMENT,
    trigger_status VARCHAR(500) NOT NULL,
    created_at DATETIME NOT NULL);

DROP TRIGGER IF EXISTS election_info_update;

DELIMITER $$

CREATE TRIGGER election_info_update
BEFORE UPDATE        
ON constituency_2018 FOR EACH ROW
BEGIN
    INSERT INTO election_info_history(constituency,cand_id,cand_name, party_id,party,winner_votes,total_valid,total_rejected,total_registered)
    VALUES(OLD.constituency,OLD.cand_id,OLD.cand_name, OLD.party_id, OLD.party, OLD.winner_votes, OLD.total_valid, OLD.total_rejected, OLD.total_registered);

    INSERT INTO trigger_history(trigger_status,created_at)
		VALUES('Old info backup successful',NOW());
END$$

DELIMITER ;

SET SQL_SAFE_UPDATES = 0;

UPDATE constituency_2018
SET total_valid = 157061
WHERE constituency = 'NA-2';
 



