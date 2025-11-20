use ig_clone;

-- Subjective Questions
-- 1.	Based on user engagement and activity levels, which users would you consider the most loyal or valuable? How would you reward or incentivize these users?

		WITH
		likes_count AS (SELECT DISTINCT user_id, COUNT(*) AS Number_of_Likes FROM likes GROUP BY user_id),
		comments_count AS (SELECT user_id, COUNT(id) AS Number_of_Comments FROM comments GROUP BY user_id),
		photo_counts AS (SELECT user_id, COUNT(*) AS Number_of_Photos FROM photos GROUP BY user_id),
		phototags_count AS (SELECT p.user_id,count(pt.tag_id) AS Number_of_Photo_Hashtags FROM photos p JOIN photo_tags AS pt ON p.user_id = pt.photo_id GROUP BY p.user_id),
		Count_of_followers AS (SELECT follower_id , count(follower_id) AS Count_of_Follower , count(followee_id) AS Count_of_Followee FROM follows GROUP BY follower_id)
		SELECT u.id AS UserID, u.username AS Username,
				COALESCE (l.Number_of_Likes,0) AS Number_of_Likes,
				COALESCE (c.Number_of_Comments,0) AS Number_of_Comments,
				COALESCE (pp.Number_of_Photos,0) AS Number_of_Photos,
				COALESCE (p.Number_of_Photo_Hashtags,0) AS Number_of_Photo_Hashtags,
				COALESCE (f.Count_of_Follower,0) AS Count_of_Follower,
				COALESCE (f.Count_of_Followee,0) AS Count_of_Followee,
				COALESCE ((COALESCE (l.Number_of_Likes,0) + COALESCE (c.Number_of_Comments,0) + COALESCE (pp.Number_of_Photos,0)),0) AS Total_Engagement,
		DENSE_RANK() OVER (ORDER BY (COALESCE (l.Number_of_Likes,0) + COALESCE (c.Number_of_Comments,0) + COALESCE (pp.Number_of_Photos,0)) DESC) AS Engagement_Rankings
		FROM users u LEFT JOIN likes_count AS l ON u.id = l.user_id
		LEFT JOIN comments_count AS c ON u.id = c.user_id
		LEFT JOIN photo_counts AS pp ON u.id = pp.user_id
		LEFT JOIN phototags_count AS p ON u.id = p.user_id
		LEFT JOIN Count_of_followers AS f ON u.id = f.follower_id
		ORDER BY Engagement_Rankings ASC ;


-- 2.	For inactive users, what strategies would you recommend to re-engage them and encourage them to start posting or engaging again?

		WITH
		likes_count AS (SELECT DISTINCT user_id, COUNT(*) AS Number_of_Likes FROM likes GROUP BY user_id),
		comments_count AS (SELECT user_id, COUNT(id) AS Number_of_Comments FROM comments GROUP BY user_id),
		photo_counts AS (SELECT user_id, COUNT(*) AS Number_of_Photos FROM photos GROUP BY user_id),
		phototags_count AS (SELECT p.user_id, COUNT(pt.tag_id) AS Number_of_Photo_Hashtags FROM photos AS p JOIN photo_tags AS pt ON p.user_id = pt.photo_id GROUP BY p.user_id),
		Count_of_followers AS (SELECT follower_id, COUNT(follower_id) AS Count_of_followers, COUNT(followee_id) AS Count_of_Followee FROM follows GROUP BY follower_id)
		SELECT u.id AS UserID, u.username AS Username,
		  COALESCE(l.Number_of_Likes, 0) AS Number_of_Likes,
		  COALESCE(c.Number_of_Comments, 0) AS Number_of_Comments,
		  COALESCE(pp.Number_of_Photos, 0) AS Number_of_Photos,
		  COALESCE(p.Number_of_Photo_Hashtags, 0) AS Number_of_Photo_Hashtags,
		  COALESCE(f.Count_of_followers, 0) AS Count_of_followers,
		  COALESCE(f.Count_of_followers, 0) AS Count_of_Followee,
		  COALESCE((COALESCE(l.Number_of_Likes, 0) + COALESCE(c.Number_of_Comments, 0) + COALESCE(pp.Number_of_Photos, 0)), 0) AS Total_Engagement,
		  DENSE_RANK() OVER (ORDER BY (COALESCE(l.Number_of_Likes, 0) + COALESCE(c.Number_of_Comments, 0) + COALESCE(pp.Number_of_Photos, 0)) ASC) AS Engagement_Rankings
		FROM users u
		LEFT JOIN likes_count AS l  ON u.id = l.user_id
		LEFT JOIN comments_count AS c  ON u.id = c.user_id
		LEFT JOIN photo_counts AS pp  ON u.id = pp.user_id
		LEFT JOIN phototags_count AS p  ON u.id = p.user_id
		LEFT JOIN Count_of_followers AS f  ON u.id = f.follower_id
		ORDER BY Engagement_Rankings ASC;


-- 3.	Which hashtags or content topics have the highest engagement rates? How can this information guide content strategy and ad campaigns?

		WITH
		Post_Engagements AS (SELECT P.id AS photo_id, COUNT(L.photo_id) AS likes, COUNT(C.photo_id) AS comments
			FROM photos P LEFT JOIN likes L ON L.photo_id = P.id AND L.created_at >= NOW() - INTERVAL 30 DAY LEFT JOIN comments C ON C.photo_id = P.id AND C.created_at >= NOW() - INTERVAL 30 DAY
			WHERE P.created_dat >= NOW() - INTERVAL 30 DAY GROUP BY P.id),
		Tagged_Engagement AS (SELECT T.id AS TagID, T.tag_name AS HastagName, COUNT(*) AS Count_of_HastagNames,
			SUM(PE.likes) AS Total_Likes, SUM(PE.comments) AS Total_Comments, AVG(PE.likes + PE.comments) AS avg_engagement_per_post
			FROM photo_tags PT JOIN Post_Engagements PE ON PE.photo_id = PT.photo_id JOIN tags T ON T.id = PT.tag_id GROUP BY T.id, T.tag_name)
		SELECT TagID, HastagName, Count_of_HastagNames, Total_Likes, Total_Comments, avg_engagement_per_post AS Average_of_Engagements, (total_likes + total_comments) AS Combined_Engagement 
		FROM Tagged_Engagement WHERE Count_of_HastagNames >= 10 ORDER BY Average_of_Engagements DESC;


-- 4.	Are there any patterns or trends in user engagement based on demographics (age, location, gender) or posting times? How can these insights inform targeted marketing campaigns?

		With
		Likes AS (SELECT photo_id, COUNT(*) 		AS	Total_Likes		FROM likes GROUP BY photo_id),
		Comments AS (SELECT photo_id, COUNT(*) 		AS	Total_Comments	FROM comments GROUP BY photo_id) 
		SELECT DATE_FORMAT(P.created_dat, '%H') 	AS	Hour_of_Day,
				DAYNAME(P.created_dat) 				AS	Day_of_Week,
				COUNT(P.id) 						AS	Total_Posts,
				COALESCE(SUM(L.Total_Likes), 2) 	AS	Total_Likes,
				COALESCE(SUM(C.Total_Comments), 2) 	AS	Total_Comments,
				ROUND((COALESCE(SUM(L.Total_Likes), 2) + COALESCE(SUM(C.Total_comments), 2)) / COUNT(P.id),2) AS Average_of_Engagement
		FROM photos	AS P 	LEFT JOIN Likes AS L ON P.id = L.photo_id 	LEFT JOIN Comments AS C ON P.id = C.photo_id GROUP BY Hour_of_Day, Day_of_Week;


-- 5.	Based on follower counts and engagement rates, which users would be ideal candidates for influencer marketing campaigns? How would you approach and collaborate with these influencers?

		WITH
		post_likes_30d 		AS (SELECT l.photo_id,	COUNT(*) AS likes_30d FROM likes l WHERE l.created_at >= NOW() - INTERVAL 30 DAY 	GROUP BY l.photo_id),
		post_comments_30d 	AS (SELECT c.photo_id,	COUNT(*) AS comments_30d FROM comments c WHERE c.created_at >= NOW() - INTERVAL 30 DAY 	GROUP BY c.photo_id),
		post_eng 			AS (SELECT p.id, p.user_id, COALESCE(pl.likes_30d, 0) AS likes_30d, COALESCE(pc.comments_30d, 0) AS comments_30d FROM photos p
								LEFT JOIN post_likes_30d pl ON pl.photo_id = p.id LEFT JOIN post_comments_30d pc ON pc.photo_id = p.id	WHERE p.created_dat >= NOW() - INTERVAL 30 DAY),
		user_eng 			AS (SELECT user_id,		COUNT(*) AS posts_30d, SUM(likes_30d) AS total_likes_30d, SUM(comments_30d) AS total_comments_30d,
								ROUND((SUM(likes_30d) + SUM(comments_30d)) / NULLIF(COUNT(*),0), 2) AS Average_of_Engagement_per_Post	From post_eng GROUP BY user_id),                            
		followers 			AS (SELECT followee_id AS user_id, COUNT(*) AS follower_count FROM follows GROUP BY followee_id),
		followees 			AS (SELECT follower_id AS user_id, COUNT(*) AS followee_count FROM follows GROUP BY follower_id),
		all_time_likes 		AS (SELECT p.user_id, COUNT(*) AS total_likes FROM photos p JOIN likes 	l ON l.photo_id = p.id GROUP BY p.user_id),
		all_time_comments 	AS (SELECT p.user_id, COUNT(*) AS total_comments FROM photos p JOIN comments c ON c.photo_id = p.id GROUP BY p.user_id),
		scored 				AS (SELECT u.id AS UserID, u.UserName,	COALESCE(f.follower_count, 0) AS Count_of_Followers,
																	COALESCE(fe.followee_count, 0) AS Count_of_Followees,
																	COALESCE(ue.posts_30d, 0) AS Posts_for_30days,
																	COALESCE(ue.Average_of_Engagement_per_Post, 0) AS Average_of_Engagement_per_Post,
																	COALESCE(al.total_likes, 0)	AS Total_Likes,
																	COALESCE(ac.total_comments, 0) AS Total_Comments,
																	COALESCE(al.total_likes, 0) + COALESCE(ac.total_comments, 0) AS Total_Engagement,
																	COALESCE(f.follower_count,0) / NULLIF(MAX(COALESCE(f.follower_count,0)) OVER (), 0) AS follower_norm,
																	COALESCE(ue.Average_of_Engagement_per_Post,0) / NULLIF(MAX(COALESCE(ue.Average_of_Engagement_per_Post,0)) OVER (), 0) AS rate_norm
								FROM users u	LEFT JOIN user_eng          ue ON ue.user_id = u.id
												LEFT JOIN followers          f ON f.user_id  = u.id
												LEFT JOIN followees         fe ON fe.user_id = u.id
												LEFT JOIN all_time_likes    al ON al.user_id = u.id
												LEFT JOIN all_time_comments ac ON ac.user_id = u.id)
		SELECT UserID, UserName, Posts_for_30days, Count_of_Followers, Count_of_Followees, Average_of_Engagement_per_Post,
				ROUND(0.6 * follower_norm + 0.4 * rate_norm, 3) AS Influencer_Score, Total_Likes, Total_Comments, Total_Engagement, ROUND(Total_Engagement / NULLIF(Count_of_Followers,0), 4) AS Engagement_rate
		FROM scored WHERE Posts_for_30days >= 3 ORDER BY influencer_score DESC, Count_of_Followers DESC;


-- 6.	Based on user behavior and engagement data, how would you segment the user base for targeted marketing campaigns or personalized recommendations?

		SELECT 	u.id AS UserID, u.username AS UserName, COALESCE(p.total_posts, 0) AS Total_Posts,
						COALESCE(l.total_likes, 0) + COALESCE(c.total_comments, 0) AS Overall_Engagement,
		CASE WHEN COALESCE(l.total_likes, 0) + COALESCE(c.total_comments, 0) > 150 THEN 'Highly Engaged'
			 WHEN COALESCE(l.total_likes, 0) + COALESCE(c.total_comments, 0) BETWEEN 100 AND 150 THEN 'Moderately Engaged' ELSE 'Less Engaged' END	AS User_Segment,
		CASE WHEN YEAR(u.created_at) >= 2017 THEN 'New_User' ELSE 'Old_User' END	AS User_Status
		FROM users u	LEFT JOIN (SELECT user_id, COUNT(*) AS total_likes 		FROM likes 		GROUP BY user_id) l ON u.id = l.user_id
						LEFT JOIN (SELECT user_id, COUNT(*) AS total_comments	FROM comments	GROUP BY user_id) c ON u.id = c.user_id
						LEFT JOIN (SELECT user_id, COUNT(*) AS total_posts		FROM photos		GROUP BY user_id) p ON u.id = p.user_id
		GROUP BY u.id, u.username, u.created_at, p.total_posts, l.total_likes, c.total_comments HAVING Total_Posts > 0	ORDER BY Overall_Engagement DESC, User_Segment;
        
        
-- 7.	If data on ad campaigns (impressions, clicks, conversions) is available, how would you measure their effectiveness and optimize future campaigns?

		CREATE TABLE ad_campaigns (
			id INT AUTO_INCREMENT PRIMARY KEY,
			campaign_name VARCHAR(255),
			impressions INT,
			clicks INT,
			conversions INT,
			cost DECIMAL(10, 2),
			revenue DECIMAL(10, 2),
			start_date DATE,
			end_date DATE
		);


-- 8.	How can you use user activity data to identify potential brand ambassadors or advocates who could help promote Instagram's initiatives or events?

		WITH
		post_counts 	AS (SELECT user_id, COUNT(*) AS total_posts	FROM photos GROUP BY user_id),
		comment_counts 	AS (SELECT user_id, COUNT(*) AS total_comments FROM comments GROUP BY user_id),
		like_counts 	AS (SELECT user_id, COUNT(DISTINCT photo_id) AS total_likes FROM likes GROUP BY user_id),
		follower_counts AS (SELECT followee_id AS user_id, 	COUNT(*) AS total_followers FROM follows GROUP BY followee_id),
		tag_usage 		AS (SELECT p.user_id,  GROUP_CONCAT(DISTINCT t.tag_name SEPARATOR ' , ') AS hashtags_used FROM photos p
							JOIN photo_tags pt ON p.id = pt.photo_id	JOIN tags t ON pt.tag_id = t.id		GROUP BY p.user_id)
		SELECT u.id AS UserID, u.username AS Username,	COALESCE(pc.total_posts, 0) AS Total_Posts,		COALESCE(lc.total_likes, 0) AS Total_Likes, 	COALESCE(fc.total_followers, 0) AS Total_Followers,
		CASE WHEN 	COALESCE(pc.total_posts, 0) = 0 THEN 0 ELSE ROUND((COALESCE(lc.total_likes, 0) + COALESCE(cc.total_comments, 0)) / pc.total_posts, 3) END AS Engagement_Rates, tu.hashtags_used AS Hashtags_Used,
		CASE WHEN 	COALESCE(pc.total_posts, 0) > 3 AND COALESCE(lc.total_likes, 0) > 80 THEN 'High Engagement User' ELSE 'Potential Influencer' END AS User_Segment
		FROM users u	LEFT JOIN post_counts     pc ON u.id = pc.user_id
						LEFT JOIN comment_counts  cc ON u.id = cc.user_id
						LEFT JOIN like_counts     lc ON u.id = lc.user_id
						LEFT JOIN follower_counts fc ON u.id = fc.user_id
						LEFT JOIN tag_usage       tu ON u.id = tu.user_id
		WHERE COALESCE(fc.total_followers, 0) > 50 AND (CASE WHEN  COALESCE(pc.total_posts, 0) = 0 THEN 0 ELSE (COALESCE(lc.total_likes, 0) + COALESCE(cc.total_comments, 0)) / pc.total_posts END) > 0.1
		ORDER BY Total_Followers DESC, Engagement_Rates DESC;


-- 9.	How would you approach this problem, if the objective and subjective questions weren't given?
		
        -- ANSWER TO THIS QUESTION IS IN THE WORD DOCUMENT FILE.
        
        
-- 10.	Assuming there's a "User_Interactions" table tracking user engagements, how can you update the "Engagement_Type" column to change all instances of "Like" to "Heart" to align with Instagram's terminology?

		UPDATE User_Interactions
		SET Engagement_Type = 'Heart'
		WHERE Engagement_Type = 'Like'
		  AND id > 0;