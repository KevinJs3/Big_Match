-- ATTENTION : il faut supprimer dans l'ordre inverse des dépendances !
DROP TABLE IF EXISTS Tag_utilisateur CASCADE;
DROP TABLE IF EXISTS Tag_evenement CASCADE;
DROP TABLE IF EXISTS Tag_lieu CASCADE;
DROP TABLE IF EXISTS Tag CASCADE;
DROP TABLE IF EXISTS Categorie CASCADE;
DROP TABLE IF EXISTS Donnee_utilisateur CASCADE;
DROP TABLE IF EXISTS Allo_cine CASCADE;
DROP TABLE IF EXISTS Spotify CASCADE;
DROP TABLE IF EXISTS Donnee CASCADE;
DROP TABLE IF EXISTS Statut_event CASCADE;
DROP TABLE IF EXISTS Organise CASCADE;
DROP TABLE IF EXISTS Evenement CASCADE;
DROP TABLE IF EXISTS Organisateur CASCADE;
DROP TABLE IF EXISTS Abonnee CASCADE;
DROP TABLE IF EXISTS Abonnement CASCADE;
DROP TABLE IF EXISTS Nope CASCADE;
DROP TABLE IF EXISTS "Like" CASCADE;
DROP TABLE IF EXISTS Utilisateur CASCADE;
DROP TABLE IF EXISTS Disponible CASCADE;
DROP TABLE IF EXISTS Disponibilite CASCADE;
DROP TABLE IF EXISTS Lieu CASCADE;
DROP TABLE IF EXISTS Ville CASCADE;


-- nombre total de table : 21

-- vaut mieux mettre la clé entre () car cela peut poser problème pour certains SGBD
-- Création des tables
CREATE TABLE Ville (
    id_ville INT PRIMARY KEY,
    nom VARCHAR(50) NOT NULL,
    pays VARCHAR(50) NOT NULL
);

CREATE TABLE Lieu(
    id_lieu INT PRIMARY KEY,
    type_lieu VARCHAR(50) NOT NULL,
    nom VARCHAR(50) NOT NULL,
    id_ville INT NOT NULL,

    FOREIGN KEY(id_ville) REFERENCES Ville(id_ville)
);

CREATE TABLE Disponibilite(
    "date" DATE PRIMARY KEY
);

CREATE TABLE Disponible(
    id_lieu INT NOT NULL,
    "date" DATE NOT NULL,

    PRIMARY KEY(id_lieu, "date"),
    FOREIGN KEY(id_lieu) REFERENCES Lieu(id_lieu),
    FOREIGN KEY("date") REFERENCES Disponibilite("date")
);

CREATE TABLE Utilisateur(
    pseudo VARCHAR(50) PRIMARY KEY,
    nom VARCHAR(50) NOT NULL,
    prenom VARCHAR(50) NOT NULL,
    date_de_naissance DATE NOT NULL,
    genre VARCHAR(50) NOT NULL,
    orientation VARCHAR(50) NOT NULL,
    taille INT NOT NULL,
    couleur_yeux VARCHAR(20) NOT NULL,
    poids FLOAT NOT NULL,
    id_ville INT NOT NULL,

    FOREIGN KEY (id_ville) REFERENCES Ville(id_ville),
    CHECK (date_de_naissance <= CURRENT_DATE - INTERVAL '18 years'),
    CHECK (couleur_yeux IN ('bleu', 'vert', 'marron', 'noir', 'violet', 'jaune')),
    CHECK (genre IN ('Homme', 'Femme', 'Non-binaire', 'Autre')),
    CHECK (orientation IN ('hétéro', 'homo', 'bi', 'asexuel', 'pan', 'sapiosexuel')),
    CHECK (poids BETWEEN 20 AND 400),
    CHECK (taille BETWEEN 80 AND 250)
);

CREATE TABLE "Like"(
    liker_pseudo VARCHAR(50) NOT NULL,
    liked_pseudo VARCHAR(50) NOT NULL,
    date_like DATE NOT NULL,

    PRIMARY KEY(liker_pseudo, liked_pseudo),
    FOREIGN KEY(liker_pseudo) REFERENCES Utilisateur(pseudo),
    FOREIGN KEY(liked_pseudo) REFERENCES Utilisateur(pseudo),
    CHECK (liker_pseudo <> liked_pseudo)
);

CREATE TABLE Nope(
    noper_pseudo VARCHAR(50) NOT NULL,
    noped_pseudo VARCHAR(50) NOT NULL,
    date_nope DATE NOT NULL,

    PRIMARY KEY(noper_pseudo, noped_pseudo),
    FOREIGN KEY(noper_pseudo) REFERENCES Utilisateur(pseudo),
    FOREIGN KEY(noped_pseudo) REFERENCES Utilisateur(pseudo),
    CHECK (noper_pseudo <> noped_pseudo)
);

CREATE TABLE Abonnement(
    -- date_abonnement DATE NOT NULL,
    -- duree_mois INT NOT NULL,
    id_abonnement INT PRIMARY KEY,
    nom VARCHAR(50) NOT NULL
);

CREATE TABLE Abonnee(
    pseudo VARCHAR(50) PRIMARY KEY,
    id_abonnement INT NOT NULL,

    FOREIGN KEY(pseudo) REFERENCES Utilisateur(pseudo),
    FOREIGN KEY (id_abonnement) REFERENCES Abonnement(id_abonnement)
);

CREATE TABLE Organisateur(
    pseudo VARCHAR(50) PRIMARY KEY,

    FOREIGN KEY(pseudo) REFERENCES Utilisateur(pseudo)
);

CREATE TABLE Evenement(
    id_evenement INT PRIMARY KEY,
    prix DECIMAL(5,2) NOT NULL,
    descriptions TEXT, -- NULL
    date_event DATE NOT NULL,
    id_lieu INT NOT NULL,

    FOREIGN KEY (id_lieu) REFERENCES Lieu(id_lieu)
);

CREATE TABLE Organise(
    pseudo VARCHAR(50) NOT NULL,
    id_evenement INT NOT NULL,

    PRIMARY KEY(pseudo, id_evenement),
    FOREIGN KEY(pseudo) REFERENCES Organisateur(pseudo),
    FOREIGN KEY(id_evenement) REFERENCES Evenement(id_evenement)
);

CREATE TABLE Statut_event (
    pseudo VARCHAR(50) NOT NULL,
    id_evenement INT NOT NULL,
    participe BOOLEAN NOT NULL DEFAULT FALSE,
    aime BOOLEAN NOT NULL DEFAULT FALSE,

    PRIMARY KEY (pseudo, id_evenement),
    FOREIGN KEY (pseudo) REFERENCES Utilisateur(pseudo),
    FOREIGN KEY (id_evenement) REFERENCES Evenement(id_evenement),
    CHECK (
        (participe = TRUE AND aime = FALSE)
        OR
        (participe = FALSE AND aime = TRUE)
        OR
        (participe = FALSE AND aime = FALSE)
    )
);

CREATE TABLE Categorie(
    id_categorie INT PRIMARY KEY,
    nom VARCHAR(50) NOT NULL
);

CREATE TABLE Tag(
    id_tag INT PRIMARY KEY,
    id_categorie INT NOT NULL,
    nom VARCHAR(50) NOT NULL,

    FOREIGN KEY (id_categorie) REFERENCES Categorie(id_categorie)
    -- un nom de tag est une précision de la catégorie donc pas le même nom que la catégorie
);

CREATE TABLE Tag_lieu (
    id_lieu INT NOT NULL,
    id_tag INT NOT NULL,

    PRIMARY KEY (id_lieu, id_tag),
    FOREIGN KEY (id_lieu) REFERENCES Lieu(id_lieu),
    FOREIGN KEY (id_tag) REFERENCES Tag(id_tag)
);

CREATE TABLE Tag_evenement (
    id_evenement INT NOT NULL,
    id_tag INT NOT NULL,

    PRIMARY KEY (id_evenement, id_tag),
    FOREIGN KEY (id_evenement) REFERENCES Evenement(id_evenement),
    FOREIGN KEY (id_tag) REFERENCES Tag(id_tag)
);

CREATE TABLE Tag_utilisateur (
    pseudo VARCHAR(50) NOT NULL,
    id_tag INT NOT NULL,
    PRIMARY KEY (pseudo, id_tag),

    FOREIGN KEY (pseudo) REFERENCES Utilisateur(pseudo),
    FOREIGN KEY (id_tag) REFERENCES Tag(id_tag)
);

CREATE TABLE Donnee(
    id_donnee INT PRIMARY KEY,
    nom VARCHAR(50) NOT NULL,
    descriptions TEXT --NULL
);

CREATE TABLE Spotify(
    id_musique INT PRIMARY KEY,

    FOREIGN KEY (id_musique) REFERENCES Donnee(id_donnee)
);

CREATE TABLE Allo_cine(
    id_film INT PRIMARY KEY,

    FOREIGN KEY (id_film) REFERENCES Donnee(id_donnee)
);

CREATE TABLE Donnee_utilisateur(
    id_donnee INT NOT NULL,
    pseudo VARCHAR(50) NOT NULL,

    PRIMARY KEY (id_donnee, pseudo), 
    FOREIGN KEY (id_donnee) REFERENCES Donnee(id_donnee),
    FOREIGN KEY (pseudo) REFERENCES Utilisateur(pseudo)
    -- Attention : ne pas oublier la clé composite pour ne pas avoir de doublons ! 
);

-- Insertions des valeurs dans les tables
\copy Ville FROM 'CSV/Ville.csv' DELIMITER ',' CSV HEADER;
\copy Lieu FROM 'CSV/Lieu.csv' DELIMITER ',' CSV HEADER;
\copy Disponibilite FROM 'CSV/Disponibilite.csv' DELIMITER ',' CSV HEADER;
\copy Disponible FROM 'CSV/Disponible.csv' DELIMITER ',' CSV HEADER;
\copy Utilisateur FROM 'CSV/Utilisateur.csv' DELIMITER ',' CSV HEADER;
\copy "Like" FROM 'CSV/Like.csv' DELIMITER ',' CSV HEADER;
\copy Nope FROM 'CSV/Nope.csv' DELIMITER ',' CSV HEADER;
\copy Abonnement FROM 'CSV/Abonnement.csv' DELIMITER ',' CSV HEADER;
\copy Abonnee FROM 'CSV/Abonnee.csv' DELIMITER ',' CSV HEADER;
\copy Organisateur FROM 'CSV/Organisateur.csv' DELIMITER ',' CSV HEADER;
\copy Evenement FROM 'CSV/Evenement.csv' DELIMITER ',' CSV HEADER;
\copy Organise FROM 'CSV/Organise.csv' DELIMITER ',' CSV HEADER;
\copy Statut_event FROM 'CSV/Statut_event.csv' DELIMITER ',' CSV HEADER;
\copy Categorie FROM 'CSV/Categorie.csv' DELIMITER ',' CSV HEADER;
\copy Tag FROM 'CSV/Tag.csv' DELIMITER ',' CSV HEADER;
\copy Tag_lieu FROM 'CSV/Tag_lieu.csv' DELIMITER ',' CSV HEADER;
\copy Tag_evenement FROM 'CSV/Tag_evenement.csv' DELIMITER ',' CSV HEADER;
\copy Tag_utilisateur FROM 'CSV/Tag_utilisateur.csv' DELIMITER ',' CSV HEADER;
\copy Donnee FROM 'CSV/Donnee.csv' DELIMITER ',' CSV HEADER;
\copy Spotify FROM 'CSV/Spotify.csv' DELIMITER ',' CSV HEADER;
\copy Allo_cine FROM 'CSV/Allo_cine.csv' DELIMITER ',' CSV HEADER;
\copy Donnee_utilisateur FROM 'CSV/Donnee_utilisateur.csv' DELIMITER ',' CSV HEADER;