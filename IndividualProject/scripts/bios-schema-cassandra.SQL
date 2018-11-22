-- Cassandra Bio Data

USE cmpe281;

DROP TABLE IF EXISTS cmpe281.PERSON ;

CREATE TABLE IF NOT EXISTS cmpe281.PERSON (
  person_id Int ,
  first_name TEXT ,
  last_name TEXT,
  birth_date DATE ,
  death_date DATE ,
  PRIMARY KEY (person_id))
;


-- -----------------------------------------------------
-- Table cmpe281.AWARDS
-- -----------------------------------------------------
DROP TABLE IF EXISTS cmpe281.AWARDS ;

CREATE TABLE IF NOT EXISTS cmpe281.AWARDS (
  award_id INT ,
  award_name TEXT,
  awarded_by TEXT,
  PRIMARY KEY (award_id))
;


-- -----------------------------------------------------
-- Table cmpe281.PERSON_AWARDS
-- -----------------------------------------------------
DROP TABLE IF EXISTS cmpe281.PERSON_AWARDS ;

CREATE TABLE IF NOT EXISTS cmpe281.PERSON_AWARDS (
  person_id INT ,
  award_id INT ,
  awarded_year DATE ,
  PRIMARY KEY (person_id, award_id)
);


-- -----------------------------------------------------
-- Table cmpe281.CONTRIBS
-- -----------------------------------------------------
DROP TABLE IF EXISTS cmpe281.CONTRIBS ;

CREATE TABLE IF NOT EXISTS cmpe281.CONTRIBS (
  contrib_id INT ,
  person_id INT ,
  contribution TEXT,
  PRIMARY KEY (contrib_id, person_id));


