-- PLUS DE 3 TABLES
\! echo "Afficher les Evenements tel que un user u1 à liké event1 et u2 et que user u2 à liké  event1"
SELECT 
    u1.pseudo as liker, 
    u2.pseudo as liked, 
    e.id_evenement, 
    e.date_event, 
    e.descriptions,
    v.nom as ville
FROM 
    "Like" l
JOIN 
    Utilisateur u1 ON l.liker_pseudo = u1.pseudo
JOIN 
    Utilisateur u2 ON l.liked_pseudo = u2.pseudo
JOIN 
    Statut_event p ON u2.pseudo = p.pseudo
JOIN 
    Evenement e ON p.id_evenement = e.id_evenement
JOIN 
    Lieu li ON e.id_lieu = li.id_lieu
JOIN 
    Ville v ON li.id_ville = v.id_ville
;


-- JOINTURE REFLEXIVE 
\! echo Afficher les gens qui se sont "like" mutuellement
SELECT 
    u1.pseudo as user_1, u2.pseudo as user_2
FROM 
    Utilisateur u1, Utilisateur u2, "Like" l1, "Like" l2
WHERE 
    u1.pseudo = l1.liker_pseudo 
    AND 
        u2.pseudo = l1.liked_pseudo 
    AND 
        u2.pseudo = l2.liker_pseudo
    AND 
        u1.pseudo = l2.liked_pseudo
    AND 
        u1.pseudo < u2.pseudo
GROUP BY 
    u1.pseudo, u2.pseudo
;


-- SOUS-REQUETE CORELLE
\! echo "Afficher les paires d'utilisateurs et calculer leur nb de donnée en communs (au moins 2 pour être pris en compte)"
SELECT 
    du1.pseudo AS utilisateur1,
    du2.pseudo AS utilisateur2,
    COUNT(*) AS nb_donnees_communes
FROM Donnee_utilisateur du1
JOIN Donnee_utilisateur du2 
    ON du1.id_donnee = du2.id_donnee 
    AND du1.pseudo < du2.pseudo
WHERE EXISTS (
    SELECT 1 FROM Spotify s WHERE s.id_musique = du1.id_donnee
    UNION
    SELECT 1 FROM Allo_cine a WHERE a.id_film = du1.id_donnee
)
GROUP BY du1.pseudo, du2.pseudo
HAVING COUNT(*) >= 2
ORDER BY nb_donnees_communes DESC;


-- SOUS-REQUÊTE DANS LE WHERE
-- PAS SUR
-- on utilise le tag de l'organisateur pour rassembler les gens sous un même tag afin de vérifier leur compatibilité (partir du principe que si quelqu'un organise c'est qu'il à un tag en rapport avec l'evenement et donc regarder si tous les gens sont en liens avec ce tag et ce pourquoi ils sont dans l'événement, on ne prendra donc pas en compte un groupe de gens qui ont tous un tag commun mais aucun avec l'organisateur car pas réaliste un concert de jazz et aucune personne qui ont un tag jazz n'est pas "logique" et peu récurrent donc ne pas considérer ce cas)
\! echo "Lieux n"'"accueillant pas d"'"événements avec des participants incompatibles"
SELECT l.id_lieu, l.nom
FROM "Lieu" l
WHERE NOT EXISTS (
    SELECT 1
    FROM 
        Evenement e
    JOIN 
        Statut_event pe ON e.id_evenement = pe.id_evenement
    JOIN 
        Organise o ON e.id_evenement = o.id_evenement  
    WHERE 
        e.id_lieu = l.id_lieu
    AND NOT EXISTS (
    SELECT 1
    FROM Tag_utilisateur tu_p
    JOIN Tag_utilisateur tu_o ON tu_p.id_tag = tu_o.id_tag
    WHERE tu_p.pseudo = pe.pseudo
      AND tu_o.pseudo = o.pseudo
    )
    AND EXISTS (
        SELECT 1 FROM Tag_utilisateur WHERE pseudo = pe.pseudo
    )
    AND EXISTS (
        SELECT 1 FROM Tag_utilisateur WHERE pseudo = o.pseudo
    )
);


\! echo Afficher les lieux auquel participe des gens sont tous de la même orientation
SELECT 
    l.id_lieu, 
    e.id_evenement,
    e.descriptions AS nom_lieu,
    v.nom,
    u.orientation AS orientation_commune
FROM Evenement e
JOIN Statut_event se ON se.id_evenement = e.id_evenement AND se.participe IS TRUE
JOIN Utilisateur u ON u.pseudo = se.pseudo
JOIN Lieu l ON l.id_lieu = e.id_lieu
JOIN Ville v ON v.id_ville = l.id_ville
WHERE e.id_evenement IN (
    SELECT se2.id_evenement
    FROM Statut_event se2
    JOIN Utilisateur u2 ON se2.pseudo = u2.pseudo
    WHERE se2.participe IS TRUE
    GROUP BY se2.id_evenement
    HAVING COUNT(DISTINCT u2.orientation) = 1
);



\! echo "Afficher le nombre moyen des événements par ville"
SELECT 
    nb_event_par_uts.ville, 
    AVG(nb_event_par_uts.nb_events)::NUMERIC(5,2) AS nombre_evenements_par_utilisateur_ville
FROM (
    SELECT 
        u.pseudo, 
        v.nom AS ville,
        COUNT(*) AS nb_events
    FROM 
        Statut_event p
    JOIN 
        Utilisateur u ON p.pseudo = u.pseudo
    JOIN 
        Evenement e ON p.id_evenement = e.id_evenement
    JOIN 
        Lieu l ON e.id_lieu = l.id_lieu
    JOIN 
        Ville v ON l.id_ville = v.id_ville
    WHERE 
        p.participe IS TRUE
    GROUP BY u.pseudo, v.nom
) AS nb_event_par_uts
GROUP BY ville;
-- sa sous requête pour bien comprendre le résultat de la requête
SELECT 
        u.pseudo, 
        v.nom AS ville,
        COUNT((u.pseudo, v.nom)) AS nb_events
FROM 
    Statut_event p
JOIN 
    Utilisateur u ON p.pseudo = u.pseudo
JOIN 
    Evenement e ON p.id_evenement = e.id_evenement
JOIN 
    Lieu l ON e.id_lieu = l.id_lieu
JOIN 
    Ville v ON l.id_ville = v.id_ville
WHERE 
    p.participe IS TRUE
GROUP BY u.pseudo, v.nom
;

SELECT * FROM "Like";
-- totalité 
\! echo "Afficher toutes les personnes qui ont liké tous les gens qui les ont liké"
SELECT 
    u.pseudo
FROM 
    Utilisateur u
JOIN 
    "Like" l1 ON l1.liker_pseudo = u.pseudo
GROUP BY u.pseudo
HAVING COUNT(DISTINCT l1.liked_pseudo) = (
  SELECT 
        COUNT(*)
  FROM 
        "Like" l2
  WHERE     
        l2.liked_pseudo = u.pseudo
    AND EXISTS (
            SELECT 1 
            FROM 
                "Like" l3 
            WHERE 
                    l3.liker_pseudo = u.pseudo 
                AND
                    l3.liked_pseudo = l2.liker_pseudo
            )
            -- la sous requête impose d'avoir le couple (a,b) (b,a) et si elle y est alors on comptabilise la ligne pour le COUNT(*)
);

-- version agrega
SELECT 
    u.pseudo
FROM 
    Utilisateur u
-- attention à mettre left join sinon cela supprime les colonne avec un miroir à vide (donc pas like en retour) et deviendra vrai pour chaque user présent !!
LEFT JOIN 
    "Like" l1 ON l1.liker_pseudo = u.pseudo
LEFT JOIN 
    "Like" l2 ON l2.liked_pseudo = u.pseudo 
                AND l2.liker_pseudo = l1.liked_pseudo
                -- même logique, si j'ai le couple (a,b) alors j'ai (b,a) aussi
GROUP BY 
    u.pseudo
HAVING 
    COUNT(l1.liker_pseudo) = COUNT(l2.liked_pseudo)
    -- On calcule le nombre de personnes qui ont liké u.pseudo (les l1.liker_pseudo) et le nombre de ces personnes que u.pseudo a likées en retour (les l2.liked_pseudo) et on vérifie que tous ceux qui ont liké u.pseudo ont bien été likés en retour.
;
-- pour bien voir la table et comprends le résultat: 
-- Nous voyons à travers cette table les likes miroir et si un miroir n'est pas présent c'est qu'il n'a pas été liké en retour et donc le count sera différent.
-- SELECT 
--     *
-- FROM 
--     Utilisateur u
-- LEFT JOIN 
--     "Like" l1 ON l1.liker_pseudo = u.pseudo
-- LEFT JOIN 
--     "Like" l2 ON l2.liked_pseudo = u.pseudo AND l2.liker_pseudo = l1.liked_pseudo
-- ;


-- REQUÊTE RÉCURSIVE 
-- si a like b et b like c alors c est suggéré à a
-- WITH RECURSIVE Access(suggestion_u1, suggestion_u2, date_suggestion) AS
-- (
--     SELECT 
--         liker_pseudo, 
--         liked_pseudo, 
--         date_like 
--     FROM "Like"

--     UNION
    
--     SELECT 
--         l.liker_pseudo, 
--         A.suggestion_u2,
--         A.date_suggestion 
--     FROM "Like" l
--     JOIN Access A ON l.liked_pseudo = A.suggestion_u1
-- )
-- SELECT 
--     suggestion_u1, 
--     suggestion_u2,
--     date_suggestion,
--     CURRENT_DATE AS today_date
-- FROM Access
-- LIMIT 11;


-- \! echo "Trouver la moyenne des likes par utilisateur " 
-- SELECT 
--     AVG(like_count) AS moyenne_likes
-- FROM (
--     SELECT 
--         liker_pseudo, 
--         COUNT(*) AS like_count
--     FROM 
--         "Like"
--     GROUP BY 
--         liker_pseudo
-- ) AS likes_par_utilisateur;

-- \echo "Trouver les paires d'utilisateurs avec au moins 3 tags en commun et qui ne se sont pas encore likés/nopés"
-- SELECT 
--     u1.pseudo AS user1,
--     u2.pseudo AS user2,
--     COUNT(DISTINCT tu1.id_tag) AS tags_communs,
--     STRING_AGG(t.nom, ', ') AS tags_partages
-- FROM 
--     Utilisateur u1
-- JOIN Tag_utilisateur tu1 ON u1.pseudo = tu1.pseudo
-- JOIN Tag t ON tu1.id_tag = t.id_tag
-- JOIN Tag_utilisateur tu2 ON t.id_tag = tu2.id_tag
-- JOIN Utilisateur u2 ON tu2.pseudo = u2.pseudo
-- WHERE 
--     u1.pseudo < u2.pseudo
--     AND NOT EXISTS (
--         SELECT 1 FROM "Like" l 
--         WHERE (l.liker_pseudo = u1.pseudo AND l.liked_pseudo = u2.pseudo)
--         OR (l.liker_pseudo = u2.pseudo AND l.liked_pseudo = u1.pseudo)
--     )
--     AND NOT EXISTS (
--         SELECT 1 FROM Nope n 
--         WHERE (n.noper_pseudo = u1.pseudo AND n.noped_pseudo = u2.pseudo)
--         OR (n.noper_pseudo = u2.pseudo AND n.noped_pseudo = u1.pseudo)
--     )
-- GROUP BY 
--     u1.pseudo, u2.pseudo
-- HAVING 
--     COUNT(DISTINCT tu1.id_tag) >= 3 
-- ;

-- \! echo "Événements avec taux de satisfaction"


-- \! echo "calcul de popularité"
-- SELECT 
--     u.pseudo,
--     COUNT(l.liked_pseudo) AS nombre_admirateurs,
--     COUNT(tu.id_tag) AS nombre_centres_interet
-- FROM Utilisateur u
-- LEFT JOIN "Like" l ON u.pseudo = l.liked_pseudo
-- LEFT JOIN Tag_utilisateur tu ON u.pseudo = tu.pseudo
-- GROUP BY u.pseudo
-- ORDER BY nombre_admirateurs DESC;

-- SELECT 
--     u.pseudo,
--     COUNT(*) AS total_lignes,
--     SUM(CASE WHEN l.liked_pseudo IS NOT NULL THEN 1 ELSE 0 END) AS admirateurs_reels,
--     SUM(CASE WHEN tu.id_tag IS NOT NULL THEN 1 ELSE 0 END) AS tags_reels
-- FROM Utilisateur u
-- LEFT JOIN "Like" l ON u.pseudo = l.liked_pseudo
-- LEFT JOIN Tag_utilisateur tu ON u.pseudo = tu.pseudo
-- GROUP BY u.pseudo
-- ORDER BY admirateurs_reels DESC;

-- SELECT 
--     u.pseudo,
--     COUNT(DISTINCT l.liker_pseudo) AS nombre_admirateurs,
--     COUNT(DISTINCT tu.id_tag) AS nombre_centres_interet,
--     COALESCE(COUNT(DISTINCT l.liker_pseudo), 0) + 
--     COALESCE(COUNT(DISTINCT tu.id_tag), 0) AS score_complet
-- FROM Utilisateur u
-- LEFT JOIN "Like" l ON u.pseudo = l.liked_pseudo
-- LEFT JOIN Tag_utilisateur tu ON u.pseudo = tu.pseudo
-- GROUP BY u.pseudo
-- ORDER BY score_complet DESC;


-- \! echo "requete fenetre"
-- SELECT 
--     mois,
--     pseudo,
--     nb_nopes,
--     tags_utilisateur,
--     rang
-- FROM (
--     SELECT 
--         TO_CHAR(n.date_nope, 'YYYY-MM') AS mois,
--         n.noped_pseudo AS pseudo,
--         COUNT(*) AS nb_nopes,
--         STRING_AGG(DISTINCT t.nom, ', ') AS tags_utilisateur,
--         DENSE_RANK() OVER (
--             PARTITION BY TO_CHAR(n.date_nope, 'YYYY-MM')
--             ORDER BY COUNT(*) DESC
--         ) AS rang
--     FROM Nope n
--     JOIN Tag_utilisateur tu ON n.noped_pseudo = tu.pseudo
--     JOIN Tag t ON tu.id_tag = t.id_tag
--     WHERE EXTRACT(YEAR FROM n.date_nope) = 2024
--     GROUP BY TO_CHAR(n.date_nope, 'YYYY-MM'), n.noped_pseudo
-- ) AS classement
-- WHERE rang <= 10
-- ORDER BY mois, rang;

-- SELECT 
--     u1.pseudo AS utilisateur1,
--     u2.pseudo AS utilisateur2,
--     ABS(EXTRACT(YEAR FROM AGE(u1.date_de_naissance)) - EXTRACT(YEAR FROM AGE(u2.date_de_naissance))) AS difference_age,
--     (SELECT COUNT(*) 
--      FROM Tag_utilisateur tu1 
--      JOIN Tag_utilisateur tu2 ON tu1.id_tag = tu2.id_tag 
--      WHERE tu1.pseudo = u1.pseudo AND tu2.pseudo = u2.pseudo) AS tags_communs,
--     ROUND(100.0 * (SELECT COUNT(*) FROM Tag_utilisateur tu1 JOIN Tag_utilisateur tu2 ON tu1.id_tag = tu2.id_tag 
--                   WHERE tu1.pseudo = u1.pseudo AND tu2.pseudo = u2.pseudo) / 
--           NULLIF((SELECT COUNT(*) FROM Tag_utilisateur WHERE pseudo = u1.pseudo), 0), 1) AS compatibilite_pct
-- FROM Utilisateur u1
-- JOIN Utilisateur u2 ON u1.pseudo < u2.pseudo
-- WHERE u1.orientation = u2.orientation
-- ORDER BY compatibilite_pct DESC, difference_age
-- LIMIT 10;


-- nombre d'evenements
-- SELECT l.nom, COUNT(*) AS nb_evenements
-- FROM Lieu l
-- JOIN Evenement e ON l.id_lieu = e.id_lieu
-- GROUP BY l.id_lieu, l.nom
-- ORDER BY nb_evenements DESC;


-- SELECT
--     CASE
--         WHEN COUNT(CASE WHEN v.nom = 'Paris' THEN 1 END) > COUNT(CASE WHEN v.nom = 'Marseille' THEN 1 END) THEN 'Paris'
--         WHEN COUNT(CASE WHEN v.nom = 'Paris' THEN 1 END) < COUNT(CASE WHEN v.nom = 'Marseille' THEN 1 END) THEN 'Marseille'
--         ELSE 'Égalité'
--     END AS vainqueur
-- FROM "Like" l
-- JOIN Utilisateur u ON l.liked_pseudo = u.pseudo
-- JOIN Ville v ON u.id_ville = v.id_ville;


-- SELECT 
--     o.pseudo,
--     COUNT(DISTINCT e.id_evenement) AS nb_events,
--     AVG(e.prix) AS avg_price,
--     (SELECT COUNT(DISTINCT se.pseudo)
--      FROM Statut_event se
--      JOIN Organise org ON se.id_evenement = org.id_evenement
--      WHERE org.pseudo = o.pseudo AND se.aime = TRUE) AS total_likes
-- FROM Organisateur o
-- JOIN Organise org ON o.pseudo = org.pseudo
-- JOIN Evenement e ON org.id_evenement = e.id_evenement
-- GROUP BY o.pseudo
-- HAVING COUNT(DISTINCT e.id_evenement) > 1
-- ORDER BY total_likes DESC
-- LIMIT 10;


-- -- lieu le plus populaire   
-- SELECT l.nom, COUNT(*) AS nb_evenements
-- FROM Lieu l
-- JOIN Evenement e ON l.id_lieu = e.id_lieu
-- GROUP BY l.id_lieu, l.nom
-- ORDER BY nb_evenements DESC
-- LIMIT 1;

