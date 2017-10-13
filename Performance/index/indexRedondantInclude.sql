




WITH    T_COLS
          AS --> retrouve les colonnes composant les index
( SELECT    i.object_id ,
            i.index_id ,
            i.key_ordinal ,
            c.name + CASE WHEN is_descending_key = 1 THEN ' DESC'
                          ELSE ''
                     END AS name ,
            is_descending_key ,
            MAX(key_ordinal) OVER ( PARTITION BY i.object_id, i.index_id,
                                    is_included_column ) AS n_keys ,
            is_included_column
  FROM      sys.index_columns AS i
            INNER JOIN sys.columns AS c ON i.object_id = c.object_id
                                           AND i.column_id = c.column_id
            INNER JOIN sys.objects AS o ON i.object_id = o.object_id
  WHERE     o."type" IN ( 'U', 'V' )
),      T_KEYS
          AS --> constitution par récursion de la liste des colonnes clef de l'index et de la liste des colonnes incluses de l'index
( SELECT    object_id ,
            index_id ,
            key_ordinal ,
            n_keys ,
            is_included_column ,
            CASE WHEN is_included_column = 0 THEN CAST(name AS NVARCHAR(MAX))
                 ELSE ''
            END AS INDEX_KEY ,
            CASE WHEN is_included_column = 1 THEN CAST(name AS NVARCHAR(MAX))
                 ELSE ''
            END AS INDEX_INC
  FROM      T_COLS
  WHERE     key_ordinal = 1
  UNION  ALL
  SELECT    c.object_id ,
            c.index_id ,
            c.key_ordinal ,
            c.n_keys ,
            k.is_included_column ,
            k.INDEX_KEY + CASE WHEN k.is_included_column = 0
                               THEN ', ' + CAST(c.name AS NVARCHAR(MAX))
                               ELSE ''
                          END ,
            k.INDEX_INC + CASE WHEN k.is_included_column = 1
                               THEN ', ' + CAST(c.name AS NVARCHAR(MAX))
                               ELSE ''
                          END
  FROM      T_KEYS AS k
            INNER  JOIN T_COLS AS c ON k.object_id = c.object_id
                                       AND k.index_id = c.index_id
                                       AND k.key_ordinal + 1 = c.key_ordinal
),      T_COMPARE
          AS --> récupération des autres éléments des index
( SELECT    i.object_id ,
            i.index_id ,
            s.name AS TABLE_SCHEMA ,
            o.name AS TABLE_NAME ,
            i.name AS INDEX_NAME ,
            INDEX_KEY ,
            NULLIF(INDEX_INC, '') AS INDEX_INCLUDE ,
            filter_definition AS INDEX_WHERE --> ligne à retirer pour version 2005
  FROM      sys.indexes AS i
            INNER JOIN sys.objects AS o ON i.object_id = o.object_id
            INNER JOIN sys.schemas AS s ON o.schema_id = s.schema_id
            INNER JOIN T_KEYS AS k ON i.object_id = k.object_id
                                      AND i.index_id = k.index_id
  WHERE     key_ordinal = n_keys
            AND o."type" IN ( 'U', 'V' )
)
    --> comparaisons des composition d'index ainsi obtenues
SELECT  i1.* ,
        CASE WHEN EXISTS ( SELECT   *
                           FROM     T_COMPARE AS i2
                           WHERE    i1.object_id = i2.object_id
                                    AND i1.index_id <> i2.index_id
                                    AND i1.INDEX_KEY = i2.INDEX_KEY )
             THEN N'REDONDANT avec '
                  + ( SELECT TOP 1
                                i2.INDEX_NAME
                      FROM      T_COMPARE AS i2
                      WHERE     i1.object_id = i2.object_id
                                AND i1.index_id <> i2.index_id
                                AND i1.INDEX_KEY = i2.INDEX_KEY
                    )
             WHEN EXISTS ( SELECT   *
                           FROM     T_COMPARE AS i2
                           WHERE    i1.object_id = i2.object_id
                                    AND i1.index_id <> i2.index_id
                                    AND i2.INDEX_KEY LIKE i1.INDEX_KEY + '%' )
             THEN 'INCLUS dans '
                  + ( SELECT TOP 1
                                i2.INDEX_NAME
                      FROM      T_COMPARE AS i2
                      WHERE     i1.object_id = i2.object_id
                                AND i1.index_id <> i2.index_id
                                AND i2.INDEX_KEY LIKE i1.INDEX_KEY + '%'
                    )
             WHEN EXISTS ( SELECT   *
                           FROM     T_COMPARE AS i2
                           WHERE    i1.object_id = i2.object_id
                                    AND i1.index_id <> i2.index_id
                                    AND i1.INDEX_KEY LIKE i2.INDEX_KEY + '%' )
             THEN 'INCLUS par '
                  + ( SELECT TOP 1
                                i2.INDEX_NAME
                      FROM      T_COMPARE AS i2
                      WHERE     i1.object_id = i2.object_id
                                AND i1.index_id <> i2.index_id
                                AND i1.INDEX_KEY LIKE i2.INDEX_KEY + '%'
                    )
             ELSE NULL
        END AS PROBLEME
FROM    T_COMPARE AS i1;

--> NOTA : la version 2005 n'implémente pas les index filtrés. Dans ce cas, veuillez retirer la ligne indiquée (", filter_definition AS INDEX_WHERE")
--> NOTA : la requête a été améliorée afin d'indiquer pour chaque index fautif, une référence à au moins un autre index et pour limiter la recherchex aux seuls index des tables et vues de l'utilisateur

