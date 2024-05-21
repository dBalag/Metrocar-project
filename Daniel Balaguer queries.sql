/* 
Query 1: 7 STEP FUNNEL QUERY 

This query summarizes count of users & count of rides x each of the 7 step funnel (the stages that the user does: Download,
Sign-up, Ride Request, Ride Accept, Ride Complete, Payment & Review), x each of the 3 platforms, x 5 age_ranges & x each 
download_date.
Its purpose is to get insights from the step funnel at a deeper level (platforms, age_ranges, download_date).
I used this dataset in Tableau to make viz and being able to answer the business questions.

*/

WITH 

downloaded AS   (SELECT count(ad.app_download_key) as downloaded, 0 as rides, ad.platform as platform, 
                coalesce (s.age_range, 'Unknown') as age, TO_CHAR(download_ts, 'MM/DD/YYYY') AS download_time                    
      			    from app_downloads as ad
      			    left JOIN signups as s ON s.session_id=ad.app_download_key
      			    GROUP BY platform, age, download_time),
       
signed AS 	(SELECT count(distinct s.user_id) as signed,  0 as rides,  ad.platform as platform, 
                coalesce (s.age_range, 'Unknown') as age,  TO_CHAR(download_ts, 'MM/DD/YYYY') AS download_time
      				from signups s
      				left JOIN app_downloads as ad ON s.session_id = ad.app_download_key
      				GROUP BY platform, age, download_time),
            
requested AS 	(SELECT count(distinct rr.user_id) as requested, count( rr.ride_id) as rides, ad.platform as platform, 
                coalesce (s.age_range, 'Unknown') as age, TO_CHAR(download_ts, 'MM/DD/YYYY') AS download_time
      				from ride_requests as rr
      				left JOIN signups as s ON s.user_id=rr.user_id
      				left JOIN app_downloads as ad ON ad.app_download_key=s.session_id
            	    		WHERE rr.request_ts is not null
      				GROUP BY platform, age, download_time),
                
accepted AS 	(SELECT count(distinct rr.user_id) as accepted, count( rr.ride_id) as rides_taken, ad.platform as platform, 
            	coalesce (s.age_range, 'Unknown')as age, TO_CHAR(download_ts, 'MM/DD/YYYY') AS download_time
      				from ride_requests as rr
      				left JOIN signups as s ON s.user_id=rr.user_id
      				left JOIN app_downloads as ad ON ad.app_download_key=s.session_id
      				WHERE rr.accept_ts is not null
      				GROUP BY platform, age, download_time),
                
completed AS 	(SELECT count(distinct rr.user_id) as completed, count( rr.ride_id) as rides_comp, ad.platform as platform, 
            	coalesce (s.age_range, 'Unknown') as age, TO_CHAR(download_ts, 'MM/DD/YYYY') AS download_time           
      				from ride_requests as rr
      				left JOIN signups as s ON s.user_id=rr.user_id
      				left JOIN app_downloads as ad ON ad.app_download_key=s.session_id
      				WHERE rr.dropoff_ts is not null
      				GROUP BY platform, age, download_time),
                
paid AS 	(SELECT count(distinct rr.user_id) as paid, count( tr.ride_id) as rides_payed, ad.platform as platform, 
                coalesce (s.age_range, 'Unknown') as age, TO_CHAR(download_ts, 'MM/DD/YYYY') AS download_time		
     	 			from transactions as tr
      				left JOIN ride_requests  as rr ON rr.ride_id=tr.ride_id
      				left JOIN signups as s ON s.user_id=rr.user_id
      				left JOIN app_downloads as ad ON ad.app_download_key=s.session_id
      				WHERE tr.charge_status = 'Approved'
      				GROUP BY platform, age, download_time),
           
reviewed as 	(SELECT count (distinct r.user_id) as reviewed, count( r.ride_id) as rides_reviewed, ad.platform as platform, 
                coalesce (s.age_range, 'Unknown') as age, TO_CHAR(download_ts, 'MM/DD/YYYY') AS download_time
            	    FROM reviews as r
            	    left JOIN ride_requests  as rr ON rr.ride_id=r.ride_id
            	    left JOIN signups as s ON s.user_id=rr.user_id
            	    left JOIN app_downloads as ad ON ad.app_download_key=s.session_id
           		GROUP BY platform, age, download_time)
    
 SELECT
        	1 AS funnel_step, 
		'download' AS funnel_name, 
		platform AS platform, 
		age as age_range,
  		download_time as download_date,
 		downloaded AS number_of_users,
  		rides AS number_of_rides
    		FROM downloaded
    
UNION ALL SELECT
        	2 AS funnel_step,
            	'signup' AS funnel_name,
            	platform AS platform, age as age_range, 
            	download_time as download_date,
            	signed AS number_of_users,
            	rides AS number_of_rides
    		FROM signed
   
UNION ALL SELECT  
		3 AS funnel_step,
            	'ride_requested' AS funnel_name,
            	platform AS platform, age as age_range,
            	download_time as download_date,
            	requested AS number_of_users,
            	rides AS number_of_rides
     		FROM requested
 
UNION ALL SELECT  
		4 AS funnel_step,
            	'ride_accepted' AS funnel_name,
        	platform AS platform, age as age_range, 
            	download_time as download_date,
            	accepted AS number_of_users,
            	rides_taken AS number_of_rides
        	FROM accepted
  
UNION ALL SELECT 
		5 AS funnel_step,
            	'ride_completed' AS funnel_name,
            	platform AS platform, age as age_range, 
            	download_time as download_date,
            	completed AS number_of_users,
            	rides_comp AS number_of_rides
            	FROM completed

UNION ALL SELECT 
		6 AS funnel_step,
            	'payment' AS funnel_name,
            	platform AS platform, age as age_range, 
           	download_time as download_date,
            	paid AS number_of_users,
            	rides_payed AS number_of_rides
            	FROM paid
 
UNION ALL SELECT 
		7 AS funnel_step,
            	'review' AS funnel_name,
            	platform AS platform, age as age_range, 
            	download_time as download_date,
            	reviewed AS number_of_users,
           	 rides_reviewed AS number_of_rides
    		FROM reviewed

ORDER BY funnel_step, platform, age_range, download_date;



/* 
Query 2: RIDES REQUESTED X HOUR

This query summarizes all the rides has been requested in each hour of the day. 
Its purpose is to summarize x each hour how many rides has been requested, with that then being able to use it in Tableau and 
viz it to answer the business question related.
*/

WITH rides_requested AS     ( SELECT EXTRACT(HOUR FROM rr.request_ts) as request_hour, ad.platform as platform, s.age_range as age_range,
                            COUNT(*) as ride_count
                            from ride_requests rr
                            LEFT JOIN signups s on rr.user_id = s.user_id
                            LEFT JOIN app_downloads ad ON s.session_id = ad.app_download_key
                            GROUP BY EXTRACT(HOUR FROM rr.request_ts), ad.platform, s.age_range)

SELECT request_hour, platform, age_range, COALESCE(ride_count, 0) as ride_count
from rides_requested
ORDER BY request_hour, platform, age_range;


