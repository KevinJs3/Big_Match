-- ATTENTION : il faut supprimer dans l'ordre inverse des dépendances !
DROP TABLE IF EXISTS interaction;
DROP TABLE IF EXISTS Type_interaction;
DROP TABLE IF EXISTS Match;
DROP TABLE IF EXISTS Notification;
DROP TABLE IF EXISTS Message;
DROP TABLE IF EXISTS Source_donnee;
DROP TABLE IF EXISTS Type_contenu;
DROP TABLE IF EXISTS Orientation;
DROP TABLE IF EXISTS Poids;
DROP TABLE IF EXISTS Couleur_yeux;
DROP TABLE IF EXISTS Genre;
DROP TABLE IF EXISTS Taille;
DROP TABLE IF EXISTS Ville;
DROP TABLE IF EXISTS Pays;

-- Création des tables
CREATE TABLE Pays (
    id_pays INT PRIMARY KEY,
    nom VARCHAR(100) NOT NULL
);
CREATE TABLE Ville (
    id_ville INT PRIMARY KEY,
    nom VARCHAR(100) NOT NULL,
    id_pays INT NOT NULL,
    FOREIGN KEY (id_pays) REFERENCES Pays(id_pays)
    -- vaut mieux mettre la clé entre () car cela peut poser problème pour certains SGBD
);
CREATE TABLE Taille (
    id_taille INT PRIMARY KEY, 
    taille INT NOT NULL
);
CREATE TABLE Genre (
    id_genre INT PRIMARY KEY,
    sexe VARCHAR(50) NOT NULL
);
CREATE TABLE Couleur_yeux (
    id_couleur INT PRIMARY KEY,
    nom VARCHAR(50) NOT NULL
);
CREATE TABLE Poids (
    id_poids INT PRIMARY KEY,
    poids INT NOT NULL
);
CREATE TABLE Orientation (
    id_orientation INT PRIMARY KEY,
    orientation_type VARCHAR(50) NOT NULL
);
CREATE TABLE Lieu(
    id_lieu INT PRIMARY KEY,
    type_lieu VARCHAR(100) NOT NULL,
    nom VARCHAR(100) NOT NULL
);
CREATE TABLE Categorie(
    id_categorie INT PRIMARY KEY,
    nom VARCHAR(100) NOT NULL,
    -- Nous sommes dans un cas d'association refléxive donc nous ne devons pas mettre la clé à NOT NULL
    -- La catégorie Musique n'a pas de catégorie parent donc NULL 
    id_parent INT, 
    FOREIGN KEY (id_parent) REFERENCES Categorie(id_categorie)
);
-- IL FAUT DETERMINER SI IL Y A UNE TABLE DE JOINTURE ENTRE MOT_CLEF ET LIEU 
CREATE TABLE Mot_clef(
    id_mot_clef INT PRIMARY KEY,
    id_categorie INT NOT NULL,
    id_lieu
    FOREIGN KEY (id_categorie) REFERENCES Categorie(id_categorie),
    FOREIGN
);


CREATE TABLE Utilisateur(
    id_utilisateur INT PRIMARY KEY,
    pseudo VARCHAR(100),
    date_de_naissance DATE,
    id_ville INT NOT NULL,
    id_genre INT NOT NULL,
    id_orientation INT NOT NULL,
    id_taille INT NOT NULL,
    id_couleur_yeux INT NOT NULL,
    id_poids INT NOT NULL,
    FOREIGN KEY (id_ville) REFERENCES Ville(id_ville),
    FOREIGN KEY (id_genre) REFERENCES Genre(id_genre),
    FOREIGN KEY (id_orientation) REFERENCES Orientation(id_orientation),
    FOREIGN KEY (id_taille) REFERENCES Taille(id_taille),
    FOREIGN KEY (id_couleur_yeux) REFERENCES Couleur_yeux(id_couleur_yeux),
    FOREIGN KEY (id_poids) REFERENCES Poids(id_poids)
);
CREATE TABLE Notification(
    id_notif INT PRIMARY KEY,
    contenu VARCHAR(100) NOT NULL,
    id_user INT NOT NULL,
    FOREIGN KEY (id_user) REFERENCES Utilisateur(id_utilisateur)
);
CREATE TABLE Type_interaction(
    id_type INT PRIMARY KEY,
    nom VARCHAR(100) NOT NULL
);
CREATE TABLE interaction(
    id_interaction INT PRIMARY KEY,
    -- annuler action ???
    id_type_interaction INT NOT NULL,
    id_user_cible INT NOT NULL,
    id_user_auteur INT NOT NULL,
    FOREIGN KEY (id_type_interaction) REFERENCES Type_interaction(id_type),
    FOREIGN KEY (id_user_cible) REFERENCES Type_interaction(id_type),
    FOREIGN KEY (id_user_auteur) REFERENCES Type_interaction(id_type),
);
CREATE TABLE Match(
    id_match INT PRIMARY KEY,
    date_match DATE,
    -- ici il n'y pas de noms spéciaux car personne ne subit ou fait l'action 
    id_user_1 INT NOT NULL,
    id_user_2 INT NOT NULL,
    FOREIGN KEY (id_user_1) REFERENCES Utilisateur(id_utilisateur),
    FOREIGN KEY (id_user_2) REFERENCES Utilisateur(id_utilisateur)
);
CREATE TABLE Message(
    id_message INT PRIMARY KEY, 
    contenu text NOT NULL
    -- les messages n'ont pas de taille fixes donc text
    id_expediteur INT NOT NULL,
    id_destinataire INT NOT NULL,
    FOREIGN KEY (id_expediteur) REFERENCES Utilisateur(id_utilisateur),
    FOREIGN KEY (id_destinataire) REFERENCES Utilisateur(id_utilisateur)
    -- ATTENTION : pas faire de clé composite car on veut qu'un même couple d'utilisateur puisse se parler
);
CREATE TABLE Type_contenu(
    id_contenu INT PRIMARY KEY,
    nom VARCHAR(100) NOT NULL 
);
CREATE TABLE Source_donnee (
    id_source_donnee INT PRIMARY KEY,
    nom_plateforme VARCHAR(100) NOT NULL,
    type_donnee VARCHAR(50) NOT NULL,
    id_contenu INT NOT NULL,
    FOREIGN KEY (id_contenu) REFERENCES Type_contenu(id_contenu)
);
CREATE TABLE Donnee_utilisateur(
    id_donnee INT NOT NULL,
    id_utilisateur INT NOT NULL,
    FOREIGN KEY (id_donnee) REFERENCES Source_donnee(id_source_donnee),
    FOREIGN KEY (id_utilisateur) REFERENCES Utilisateur(id_utilisateur),
    PRIMARY KEY (id_donnee, id_utilisateur) 
    -- Attention : ne pas oublier la clé composite pour ne pas avoir de doublons ! 
);








