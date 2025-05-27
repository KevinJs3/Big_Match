WITH affinite AS (
    SELECT 
        u1.pseudo AS user1,
        u2.pseudo AS user2,
        -- Score d'affinité (0-100)
        ROUND(10.0 * (
            -- on va prendre tag(u1) INTER tag(u2) et divisé par somme(tag(u1)) cela nous donnera la proportion des tags de u1 chez u2
            0.3 * (SELECT COUNT(*) 
                  FROM Tag_utilisateur tu1 
                  JOIN Tag_utilisateur tu2 ON tu1.id_tag = tu2.id_tag 
                  WHERE tu1.pseudo = u1.pseudo AND tu2.pseudo = u2.pseudo) /
            NULLIF((SELECT COUNT(*) FROM Tag_utilisateur WHERE pseudo = u1.pseudo), 0) -- renvoie NULL si il n'a pas de tag
            
            + 0.2 * 
            CASE 
                -- ici pas de problème nous avons 100% de compatiblité
                WHEN u1.orientation = u2.orientation THEN 1
                -- une chance sur deux que la personne ne soit pas du même orientation
                WHEN u1.orientation = 'bi' OR u2.orientation = 'bi' THEN 0.8
                -- si l'une des personne est pan ou sapiosexuel il y a 50% de chance que ce soit compatible 
                WHEN u1.orientation IN ('pan', 'sapiosexuel') OR u2.orientation IN ('pan', 'sapiosexuel') THEN 0.5
                -- une personne asexuel à peu de chance d'être compatible par rapport à la population
                WHEN u1.orientation = 'asexuel' OR u2.orientation = 'asexuel' THEN 0.1
                ELSE 0.2 
            END
            
            + 0.15 * 
            CASE 
                WHEN u1.id_ville = u2.id_ville THEN 1
                WHEN v1.pays = v2.pays THEN 0.6
                ELSE 0.2
            END
            
            -- donnée en commun
            + 0.15 * 
            (
                SELECT COUNT(*) 
                FROM Donnee_utilisateur du1 
                JOIN Donnee_utilisateur du2 ON du1.id_donnee = du2.id_donnee
                WHERE du1.pseudo = u1.pseudo AND du2.pseudo = u2.pseudo
            ) /
            NULLIF((SELECT COUNT(*) FROM Donnee_utilisateur WHERE pseudo = u1.pseudo), 0)
            
            -- si u1 like un utilisateur et que ce même utilisateur à like u2 alors nous avons de forte chance que u1 apprécie u2
            + 0.2 * (SELECT COUNT(*) 
                    FROM "Like" l1 
                    JOIN "Like" l2 ON l1.liked_pseudo = l2.liker_pseudo
                    WHERE l1.liker_pseudo = u1.pseudo AND l2.liked_pseudo = u2.pseudo)
        ), 1) AS score_affinité,
        
        -- on concatène les tags en communs entre u1 et u2 pour l'affichage 
        (
            SELECT STRING_AGG(t.nom, ', ') 
            FROM Tag_utilisateur tu1 
            JOIN Tag_utilisateur tu2 ON tu1.id_tag = tu2.id_tag
            JOIN Tag t ON tu1.id_tag = t.id_tag
            WHERE tu1.pseudo = u1.pseudo AND tu2.pseudo = u2.pseudo
        ) AS meme_tag,
        --  on concatène les donnée utilisateur (spotify et Allo-ciné) qu'ils ont en commun
        (
            SELECT STRING_AGG(d.nom, ', ') 
            FROM Donnee_utilisateur du1 
            JOIN Donnee_utilisateur du2 ON du1.id_donnee = du2.id_donnee
            JOIN Donnee d ON du1.id_donnee = d.id_donnee
            WHERE du1.pseudo = u1.pseudo AND du2.pseudo = u2.pseudo
        ) AS meme_interet
    FROM 
        Utilisateur u1
    JOIN 
        Utilisateur u2 ON u1.pseudo < u2.pseudo
    JOIN 
        Ville v1 ON u1.id_ville = v1.id_ville
    JOIN 
        Ville v2 ON u2.id_ville = v2.id_ville
    WHERE 
        -- Filtres de base
        u1.genre <> u2.genre  -- Pour hétérosexuels
        AND NOT EXISTS (
            SELECT 1 FROM Nope n 
            WHERE (n.noper_pseudo = u1.pseudo AND n.noped_pseudo = u2.pseudo)
               OR (n.noper_pseudo = u2.pseudo AND n.noped_pseudo = u1.pseudo)
        )
),

-- recommandations de deux événements poru les deux utilisateurs en fonction de...
recommandation_event AS (
    SELECT
        u.pseudo,
        e.id_evenement,
        e.descriptions AS event_name,
        l.nom AS lieu,
        ROUND(10.0 * (
            0.4 * (SELECT COUNT(*) 
                  FROM Tag_utilisateur tu
                  JOIN Tag_evenement te ON tu.id_tag = te.id_tag
                  WHERE tu.pseudo = u.pseudo AND te.id_evenement = e.id_evenement) /
            NULLIF((SELECT COUNT(*) FROM Tag_utilisateur WHERE pseudo = u.pseudo), 0)
            
            + 0.3 * 
            (SELECT AVG(
                        -- on va calculer le nombre de tag en commun avec chaque utilisateur présent à l'évenement 
                        -- on applique la même logique que pour la première table temporaire mais en faisant une moyenne 
                        (SELECT COUNT(*) 
                         FROM Tag_utilisateur tu_p
                         JOIN Tag_utilisateur tu_u ON tu_p.id_tag = tu_u.id_tag
                         WHERE tu_p.pseudo = pe.pseudo AND tu_u.pseudo = u.pseudo)::FLOAT /
                        NULLIF((SELECT COUNT(*) FROM Tag_utilisateur WHERE pseudo = u.pseudo), 0)
                    )::numeric
                    FROM Statut_event pe WHERE pe.id_evenement = e.id_evenement AND pe.participe = TRUE)
            
            + 0.2 * 
                    -- calcul de la popularité d'un événement en prenant le nombre de participant à un evenement u1 et on le divise par la moyenne totale des autres events -> on divise par la moyenne pour avoir le coéfficent multicplicatif pour savoir si on est mieux ou moins bien que la moyenne !!
                    (SELECT COUNT(*) FROM Statut_event se
                    WHERE se.id_evenement = e.id_evenement AND se.participe = TRUE)
                    / 
                    NULLIF((
                        SELECT AVG(part_count) FROM (
                            SELECT COUNT(*) AS part_count 
                            FROM Statut_event 
                            WHERE participe = TRUE 
                            GROUP BY id_evenement
                        ) AS avg_participation
                    ), 0)
            
            + 0.1 * CASE WHEN u.id_ville = l.id_ville THEN 1 ELSE 0.3 END
        ), 1) AS evenement_score
    FROM
        Utilisateur u,
        Evenement e
    JOIN
        Lieu l ON e.id_lieu = l.id_lieu
    WHERE
    -- on recommande des événements pour u1 donc on enlève l'ensemble des événements auquel il va participé ou à liké
        e.date_event > CURRENT_DATE
        AND NOT EXISTS (
            SELECT 1 FROM Statut_event se 
            WHERE se.pseudo = u.pseudo AND se.id_evenement = e.id_evenement 
        )
)

-- Résultats finaux
-- SELECT * FROM recommandation_event
-- LIMIT 10;

SELECT * FROM (
    SELECT 
        'PROFILE' AS recommendation_type,
        ua.user1,
        ua.user2 AS "user2/event",
        ua.score_affinité,
        ua.meme_tag,
        ua.meme_interet
    FROM 
        affinite ua
    WHERE 
        ua.score_affinité > 5 -- chiffre choisit comme ça, on estime qu'il faut au moins un score de 7 pour pouvoir valider le profil
    ORDER BY 
        ua.score_affinité DESC
    LIMIT 5
) AS profile_recos

UNION ALL

SELECT * FROM (
    SELECT 
        'EVENT' AS recommendation_type,
        er.pseudo AS user1,
        er.id_evenement::TEXT AS "user2/event",
        er.evenement_score AS afinité_score,
        er.event_name AS meme_tag,
        er.lieu AS meme_interet
    FROM 
        recommandation_event er
    WHERE 
        er.evenement_score > 2
    ORDER BY 
        er.evenement_score DESC
    LIMIT 5
) AS event_recos;




