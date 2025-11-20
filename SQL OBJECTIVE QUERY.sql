use ig_clone;

-- OBJECTIVE QUESTIONS
-- 1.	Are there any tables with duplicate or missing null values? If so, how would you handle them?

	-- "DUPLICATES VALUES"
		-- comments table
			SELECT * FROM comments GROUP BY id HAVING COUNT(*) > 1;
		-- follows table
			SELECT *, COUNT(*) AS DUPLICATE FROM follows GROUP BY follower_id, followee_id HAVING COUNT(*) > 1;
		-- likes table
			SELECT *, COUNT(*) as DUPLICATE FROM likes GROUP BY photo_id, user_id HAVING COUNT(*) > 1;
		-- photo_tags table
			SELECT *, COUNT(*) AS DUPLICATE FROM photo_tags GROUP BY photo_id, tag_id HAVING COUNT(*) > 1;
		-- photos table
			SELECT * FROM photos GROUP BY id HAVING COUNT(*) > 1;
		-- tags table
			SELECT * FROM tags GROUP BY id HAVING COUNT(*) > 1;
		-- users table
			SELECT * FROM users GROUP BY id HAVING COUNT(*) > 1;

	-- "NULL VALUES"
		-- comments table
			SELECT * FROM comments WHERE id IS NULL OR comment_text IS NULL OR user_id IS NULL OR photo_id IS NULL OR created_at IS NULL;
		-- follows table
			SELECT * FROM follows WHERE follower_id IS NULL OR followee_id IS NULL OR created_at IS NULL;
		-- likes table
			SELECT * FROM likes WHERE user_id IS NULL OR photo_id IS NULL OR created_at IS NULL;
		-- photo_tags table
			SELECT * FROM photo_tags WHERE photo_id IS NULL OR tag_id IS NULL;
		-- photos table
			SELECT * FROM photos WHERE id IS NULL OR image_url IS NULL OR user_id IS NULL OR created_dat IS NULL;
		-- tags table
			SELECT * FROM tags WHERE id IS NULL OR tag_name IS NULL OR created_at IS NULL;
		-- users table
			SELECT * FROM users WHERE id IS NULL OR username IS NULL OR created_at IS NULL;


-- 2.	What is the distribution of user activity levels (e.g., number of posts, likes, comments) across the user base?

		SELECT U.id, U.username,
			   COUNT(DISTINCT P.id) AS Number_of_Posts,
			   COUNT(DISTINCT L.photo_id) AS Number_of_Likes,
			   COUNT(DISTINCT C.id) AS Number_of_Comments
		FROM users U
		LEFT JOIN photos P ON U.id = P.user_id
		LEFT JOIN likes L ON U.id = L.user_id
		LEFT JOIN comments C ON U.id = C.user_id
		GROUP BY U.id, U.username
		ORDER BY (Number_of_Posts+Number_of_Likes+Number_of_Comments) DESC;
    

-- 3.	Calculate the average number of tags per post (photo_tags and photos tables).
		
        SELECT ROUND( COUNT(tag_id) / COUNT(DISTINCT photo_id), 2) Average_Tags_per_Posts FROM photo_tags;
        

-- 4.	Identify the top users with the highest engagement rates (likes, comments) on their posts and rank them.

		With Total_likes AS (SELECT U.username , COUNT(L.user_id) as TOTAL_Likes
        FROM users AS U LEFT JOIN likes AS L ON U.id = L.user_id GROUP BY U.username ),
        Total_comments AS (SELECT U.username , COUNT(C.user_id) AS TOTAL_Comments 
        FROM users AS U LEFT JOIN comments AS C ON U.id = C.user_id GROUP BY U.username )
        SELECT L.username , L.TOTAL_Likes , C.TOTAL_Comments , (L.TOTAL_Likes+C.TOTAL_Comments) AS TOTAL_Engagements,
        DENSE_RANK() OVER (ORDER BY (L.TOTAL_Likes+C.TOTAL_Comments) DESC) AS Highest_Engagements_Ranking
        FROM TOTAL_Likes AS L JOIN TOTAL_Comments AS C ON L.username=C.username;


-- 5.	Which users have the highest number of followers and followings?

		SELECT U.id AS user_id, U.username, COUNT(DISTINCT F1.follower_id) AS HIGHEST_FOLLOWERS, COUNT(DISTINCT F2.followee_id) AS HIGHEST_FOLLOWINGS
        FROM users U LEFT JOIN follows F1 ON U.id = F1.followee_id LEFT JOIN follows F2 ON U.id = F2.follower_id
        GROUP BY U.id, U.username ORDER BY HIGHEST_FOLLOWERS DESC, HIGHEST_FOLLOWINGS DESC;


-- 6.	Calculate the average engagement rate (likes, comments) per post for each user.        

		SELECT U.id , U.username,
		COUNT(DISTINCT L.user_id) + COUNT(DISTINCT C.id) AS Total_Engagements,
		COUNT(DISTINCT P.id) AS Number_of_Posts,
		ROUND( (COUNT(DISTINCT L.user_id) + COUNT(DISTINCT C.id)) / NULLIF(COUNT(DISTINCT P.id) , 0) , 2) AS Average_EngagementRate_per_Post
		FROM users U
		LEFT JOIN photos P ON U.id = P.user_id
		LEFT JOIN likes L ON P.id = L.photo_id
		LEFT JOIN comments C ON P.id = C.photo_id
		GROUP BY U.id, U.username
		ORDER BY Average_EngagementRate_per_Post DESC;


-- 7.	Get the list of users who have never liked any post (users and likes tables)
		
        SELECT U.id, U.username FROM users U LEFT JOIN likes L ON U.id = L.user_id WHERE L.user_id IS NULL;
  
  
-- 8.	How can you leverage user-generated content (posts, hashtags, photo tags) to create more personalized and engaging ad campaigns?

		SELECT T.tag_name, COUNT(PT.photo_id) AS TAG_NAME_TOTAL_COUNTS FROM tags T
        JOIN photo_tags PT ON T.id = PT.tag_id GROUP BY T.tag_name ORDER BY TAG_NAME_TOTAL_COUNTS DESC;

		SELECT U.id, U.username, T.tag_name FROM users U
        JOIN likes L ON U.id = L.user_id
		JOIN photos P ON L.photo_id = P.id
        JOIN photo_tags PT ON P.id = PT.photo_id
		JOIN tags T ON PT.tag_id = T.id
        GROUP BY T.tag_name, U.username, U.id;
        
        
-- 9.	Are there any correlations between user activity levels and specific content types (e.g., photos, videos, reels)? How can this information guide content creation and curation strategies?

		WITH UPLOADS AS (SELECT U.id, COUNT(P.id) AS PHOTOS_UPLOADED FROM users U
		LEFT JOIN photos P ON U.id = P.user_id GROUP BY U.id),
		likes AS (SELECT U.id, COUNT(L.photo_id) AS TOTAL_LIKES FROM users U
		LEFT JOIN photos P ON U.id = P.user_id LEFT JOIN likes L ON L.photo_id = P.id
		GROUP BY U.id),
		comments AS (SELECT U.id, COUNT(C.id) AS TOTAL_COMMENTS FROM users U
		LEFT JOIN photos P ON U.id = P.user_id LEFT JOIN comments C ON C.photo_id = P.id
		GROUP BY U.id)
		SELECT UP.id, UP.PHOTOS_UPLOADED, ROUND(AVG(L.TOTAL_LIKES + C.TOTAL_COMMENTS) OVER(PARTITION BY UP.PHOTOS_UPLOADED), 0) AS AVERAGE_ENGAGEMENTS
		FROM uploads UP JOIN likes L ON UP.id = L.id JOIN comments C ON UP.id = C.id ORDER BY UP.PHOTOS_UPLOADED;
        
        
-- 10.	Calculate the total number of likes, comments, and photo tags for each user.

		SELECT U.id, U.username,
			COALESCE(L.Total_Likes, 0) AS Total_Number_of_Likes,
			COALESCE(C.Total_Comments, 0) AS Total_Number_of_Comments,
			COALESCE(PT.Total_Photo_Tags, 0) AS Total_Number_of_Photo_Tags
		FROM users U
		LEFT JOIN ( SELECT P.user_id, COUNT(*) AS Total_Likes FROM photos P
					LEFT JOIN likes L ON P.id = L.photo_id GROUP BY P.user_id ) L ON U.id = L.user_id
		LEFT JOIN (	SELECT P.user_id, COUNT(*) AS Total_Comments FROM photos P
					LEFT JOIN comments C ON P.id = C.photo_id GROUP BY P.user_id ) C ON U.id = C.user_id
		LEFT JOIN (	SELECT P.user_id, COUNT(*) AS Total_Photo_Tags FROM photos P
					LEFT JOIN photo_tags PT ON P.id = PT.photo_id GROUP BY P.user_id ) PT ON U.id = PT.user_id
		ORDER BY Total_Likes DESC, Total_Comments DESC;


-- 11.	Rank users based on their total engagement (likes, comments, shares) over a month.

		WITH MonthlyEngagement AS
		(
			SELECT U.id, U.username,
			COALESCE(L.Total_Likes,0) AS Total_Engagement_Likes, COALESCE(C.Total_Comments,0) AS Total_Engagement_Comments,
			(COALESCE(L.Total_Likes, 0) + COALESCE(C.Total_Comments, 0)) AS Total_ENGAGEMENTS
			FROM users U
            LEFT JOIN
				(	SELECT user_id, COUNT(photo_id) AS Total_Likes FROM likes
					WHERE DATE(created_at) >= '2024-07-01' OR DATE(created_at) <= '2024-07-31' GROUP BY user_id
				) L ON U.id = L.user_id
			LEFT JOIN
				(	SELECT user_id, COUNT(id) AS Total_Comments FROM comments
					WHERE DATE(created_at) >= '2024-07-01' OR DATE(created_at) <= '2024-07-31' GROUP BY user_id
				) C ON U.id = C.user_id
		)
		SELECT id, username, Total_Engagement_Likes, Total_Engagement_Comments, Total_ENGAGEMENTS,
		RANK() OVER (ORDER BY Total_ENGAGEMENTS DESC) AS TOTAL_ENGAGEMENTS_RANKINS
		FROM MonthlyEngagement ORDER BY TOTAL_ENGAGEMENTS_RANKINS;
        
        
-- 12.	Retrieve the hashtags that have been used in posts with the highest average number of likes. Use a CTE to calculate the average likes for each hashtag first.

		WITH LIKES_PER_POST AS
		(	SELECT P.id, COUNT(l.user_id) AS Likes_Count FROM photos P
			LEFT JOIN likes L ON L.photo_id = P.id GROUP BY P.id
		),
		AVERAGE_LIKES_PER_HASTAG AS
		(	SELECT T.id, T.tag_name AS Hashtag_name, AVG(LPP.Likes_Count) AS AVERAGE_LIKES_PER_POST
			FROM photo_tags PT JOIN tags T ON T.id = PT.tag_id JOIN LIKES_PER_POST LPP ON LPP.id = PT.photo_id
			GROUP BY T.id, T.tag_name
		)
		SELECT id, Hashtag_name, ROUND(AVERAGE_LIKES_PER_POST, 2) AS HIGHEST_AVERAGE_LIKES_PER_POST
		FROM AVERAGE_LIKES_PER_HASTAG ORDER BY HIGHEST_AVERAGE_LIKES_PER_POST DESC;


-- 13.	Retrieve the users who have started following someone after being followed by that person

		SELECT f1.follower_id AS User_id, f1.followee_id AS Followed_User, f1.created_at  AS Followed_Date, f2.created_at  AS Followed_Back_Date
		FROM follows f1 JOIN follows f2 ON f1.follower_id = f2.followee_id AND f1.followee_id = f2.follower_id
		WHERE f2.created_at < f1.created_at ORDER BY f1.follower_id, f1.created_at;
