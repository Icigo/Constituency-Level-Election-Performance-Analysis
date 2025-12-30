
SELECT * FROM dim_states_codes;
SELECT * FROM constituency_wise_results_2014;
SELECT * FROM constituency_wise_results_2019;


-- 1. List top 5 / bottom 5 constituencies of 2014 and 2019 in terms of voter turnout ratio?

WITH cte AS (
SELECT pc_name, '2014' AS year, SUM(total_votes) * 100.0 / SUM(total_electors) AS voter_turnout_ratio 
FROM constituency_wise_results_2014
GROUP BY pc_name
UNION ALL
SELECT pc_name, '2019' AS year, SUM(total_votes) * 100.0 / SUM(total_electors) AS voter_turnout_ratio 
FROM constituency_wise_results_2019
GROUP BY pc_name
)
SELECT pc_name AS constituencies, year, CONCAT(FORMAT(voter_turnout_ratio, '00.00'), ' %') AS voter_turnout_ratio, top_5
FROM (
	SELECT *, ROW_NUMBER() OVER(PARTITION BY year ORDER BY voter_turnout_ratio DESC) AS top_5
	FROM cte 
) K
WHERE top_5 <= 5;


WITH cte AS (
SELECT pc_name, '2014' AS year, SUM(total_votes) * 100.0 / SUM(total_electors) AS voter_turnout_ratio 
FROM constituency_wise_results_2014
GROUP BY pc_name
UNION ALL
SELECT pc_name, '2019' AS year, SUM(total_votes) * 100.0 / SUM(total_electors) AS voter_turnout_ratio 
FROM constituency_wise_results_2019
GROUP BY pc_name
)
SELECT pc_name AS constituencies, year, CONCAT(FORMAT(voter_turnout_ratio, '0.00'), ' %') AS voter_turnout_ratio, bottom_5
FROM (
	SELECT *, ROW_NUMBER() OVER(PARTITION BY year ORDER BY voter_turnout_ratio) AS bottom_5
	FROM cte 
) K
WHERE bottom_5 <= 5;


-- 2. List top 5 / bottom 5 states of 2014 and 2019 in terms of voter turnout ratio?

WITH cte AS (
SELECT state, '2014' AS year, SUM(total_votes) * 100.0 / SUM(total_electors) AS voter_turnout_ratio
FROM constituency_wise_results_2014
GROUP BY state
UNION ALL
SELECT state, '2019' AS year, SUM(total_votes) * 100.0 / SUM(total_electors) AS voter_turnout_ratio
FROM constituency_wise_results_2019
GROUP BY state
)
SELECT state, year, CONCAT(FORMAT(voter_turnout_ratio, '00.00'), ' %') AS voter_turnout_ratio, top_5
FROM (
	SELECT *, ROW_NUMBER() OVER(PARTITION BY year ORDER BY voter_turnout_ratio DESC) AS top_5
	FROM cte
) p
WHERE top_5 <= 5;


WITH cte AS (
SELECT state, '2014' AS year, SUM(total_votes) * 100.0 / SUM(total_electors) AS voter_turnout_ratio
FROM constituency_wise_results_2014
GROUP BY state
UNION ALL
SELECT state, '2019' AS year, SUM(total_votes) * 100.0 / SUM(total_electors) AS voter_turnout_ratio
FROM constituency_wise_results_2019
GROUP BY state
)
SELECT state, year, CONCAT(FORMAT(voter_turnout_ratio, '0.00'), ' %') AS voter_turnout_ratio, bottom_5
FROM (
	SELECT *, ROW_NUMBER() OVER(PARTITION BY year ORDER BY voter_turnout_ratio) AS bottom_5
	FROM cte
) p
WHERE bottom_5 <= 5;


-- 3. Which constituencies have elected the same party for two consecutive elections, rank them by % of votes to that winning party in 2019

WITH constituency_stats AS (
SELECT pc_name, '2014' AS year, SUM(total_votes) AS total_votes
FROM constituency_wise_results_2014
GROUP BY pc_name
UNION ALL
SELECT pc_name, '2019' AS year, SUM(total_votes) AS total_votes
FROM constituency_wise_results_2019
GROUP BY pc_name
),
winner_2014 AS (
SELECT c.pc_name, c.party, c.total_votes AS party_votes_2014, s.total_votes, c.total_votes * 100.0 / s.total_votes AS vote_share,
ROW_NUMBER() OVER(PARTITION BY c.pc_name ORDER BY c.total_votes DESC) AS rn
FROM constituency_wise_results_2014 c
JOIN constituency_stats s ON c.pc_name = s.pc_name AND s.year = 2014
),
winner_2019 AS (
SELECT c.pc_name, c.party, c.total_votes AS party_votes_2019, s.total_votes, c.total_votes * 100.0 / s.total_votes AS vote_share,
ROW_NUMBER() OVER(PARTITION BY c.pc_name ORDER BY c.total_votes DESC) AS rn
FROM constituency_wise_results_2019 c
JOIN constituency_stats s ON c.pc_name = s.pc_name AND s.year = 2019
)
SELECT w14.pc_name AS constituency_name, w14.party AS winning_party, w14.party_votes_2014, w14.total_votes, 
CONCAT(FORMAT(w14.vote_share, '0.00'), ' %') AS vote_share_2014, w19.party_votes_2019, w19.total_votes, 
CONCAT(FORMAT(w19.vote_share, '0.00'), ' %') AS vote_share_2019, 
RANK() OVER(ORDER BY w19.vote_share DESC) AS rank_2019_vote_share
FROM winner_2014 w14
JOIN winner_2019 w19 ON w14.pc_name = w19.pc_name AND w14.party = w19.party
WHERE w14.rn = 1 AND w19.rn = 1;


-- 4. Which constituencies have voted for different parties in two elections (list top 10 based on difference (2019-2014) 
--    in winner vote percentage in two elections)

WITH constituency_stats AS (
SELECT pc_name, '2014' AS year, SUM(total_votes) AS total_votes
FROM constituency_wise_results_2014
GROUP BY pc_name
UNION ALL
SELECT pc_name, '2019' AS year, SUM(total_votes) AS total_votes
FROM constituency_wise_results_2019
GROUP BY pc_name
),
winner_2014 AS (
SELECT c.pc_name, c.party, c.total_votes AS party_votes_2014, s.total_votes, c.total_votes * 100.0 / s.total_votes AS vote_share,
ROW_NUMBER() OVER(PARTITION BY c.pc_name ORDER BY c.total_votes DESC) AS rn
FROM constituency_wise_results_2014 c
JOIN constituency_stats s ON c.pc_name = s.pc_name AND s.year = 2014
),
winner_2019 AS (
SELECT c.pc_name, c.party, c.total_votes AS party_votes_2019, s.total_votes, c.total_votes * 100.0 / s.total_votes AS vote_share,
ROW_NUMBER() OVER(PARTITION BY c.pc_name ORDER BY c.total_votes DESC) AS rn
FROM constituency_wise_results_2019 c
JOIN constituency_stats s ON c.pc_name = s.pc_name AND s.year = 2019
)
SELECT *
FROM (
	SELECT w14.pc_name AS constituency_name, w14.party AS winning_party_2014, w14.party_votes_2014,  w14.total_votes AS total_votes_2014, 
	CONCAT(FORMAT(w14.vote_share, '0.00'), ' %') AS vote_share_2014, w19.party AS winning_party_2019, w19.party_votes_2019, 
	w19.total_votes AS total_votes_2019, 
	CONCAT(FORMAT(w19.vote_share, '0.00'), ' %') AS vote_share_2019, CONCAT(FORMAT(w19.vote_share - w14.vote_share, '0.00'), ' %') AS diff_winner_vote_share_change,
	RANK() OVER(ORDER BY (w19.vote_share - w14.vote_share) DESC) AS rank_diff_voteshare
	FROM winner_2014 w14
	JOIN winner_2019 w19 ON w14.pc_name = w19.pc_name AND w14.party <> w19.party
	WHERE w14.rn = 1 AND w19.rn = 1
) G
WHERE rank_diff_voteshare <= 10;


-- 5. Top 5 candidates based on margin difference with runners in 2014 and 2019.

WITH candidate_2014 AS (
SELECT candidate AS runner_candidate_name_2014, SUM(total_votes) AS runner_total_votes_2014, 
LAG(SUM(total_votes)) OVER(ORDER BY SUM(total_votes) DESC) AS winner_total_votes_2014,
LAG(SUM(total_votes)) OVER(ORDER BY SUM(total_votes) DESC) - SUM(total_votes) AS margin_2014
FROM constituency_wise_results_2014
GROUP BY candidate
)
SELECT *
FROM (
	SELECT *, ROW_NUMBER() OVER(ORDER BY margin_2014 DESC) AS rank_2014
	FROM candidate_2014
) u
WHERE rank_2014 <= 5;


WITH candidate_2019 AS (
SELECT candidate AS runner_candidate_name_2019, SUM(total_votes) AS runner_total_votes_2019, 
LAG(SUM(total_votes)) OVER(ORDER BY SUM(total_votes) DESC) AS winner_total_votes_2019,
LAG(SUM(total_votes)) OVER(ORDER BY SUM(total_votes) DESC) - SUM(total_votes) AS margin_2019
FROM constituency_wise_results_2019
GROUP BY candidate
)
SELECT *
FROM (
	SELECT *, ROW_NUMBER() OVER(ORDER BY margin_2019 DESC) AS rank_2019
	FROM candidate_2019
) u
WHERE rank_2019 <= 5;


-- 6. % Split of votes of parties between 2014 vs 2019 at national level

WITH cte1 AS (
SELECT party, SUM(total_votes) AS national_votes_2014, (SELECT SUM(total_votes) FROM constituency_wise_results_2014) AS total_2014
FROM constituency_wise_results_2014
GROUP BY party
),
cte2 AS (
SELECT party, SUM(total_votes) AS national_votes_2019, (SELECT SUM(total_votes) FROM constituency_wise_results_2019) AS total_2019
FROM constituency_wise_results_2019
GROUP BY party
)
SELECT *, 
CASE WHEN votes_2014 = 0 THEN 100 ELSE (vote_share_2019_pct - vote_share_2014_pct) / vote_share_2014_pct END AS pct_change_in_share
FROM (
	SELECT COALESCE(c1.party, c2.party) AS party, COALESCE(c1.national_votes_2014, 0) AS votes_2014, 
	COALESCE(c1.national_votes_2014, 0) * 100.0 / c1.total_2014 AS vote_share_2014_pct,
	COALESCE(c2.national_votes_2019, 0) AS votes_2019, COALESCE(c2.national_votes_2019, 0) * 100.0 / c2.total_2019 AS vote_share_2019_pct,
	(COALESCE(c2.national_votes_2019, 0) * 100.0 / c2.total_2019) - (COALESCE(c1.national_votes_2014, 0) * 100.0 / c1.total_2014) AS pct_point_change
	FROM cte1 c1
	FULL OUTER JOIN cte2 c2 ON c1.party = c2.party
) Y
WHERE vote_share_2014_pct IS NOT NULL AND vote_share_2019_pct IS NOT NULL;


-- 7. % Split of votes of parties between 2014 vs 2019 at state level.

WITH cte AS (
SELECT state, '2014' AS year, SUM(total_votes) AS state_total
FROM constituency_wise_results_2014
GROUP BY state
UNION ALL
SELECT state, '2019' AS year, SUM(total_votes) AS state_total
FROM constituency_wise_results_2019
GROUP BY state
),
state_party_2014 AS (
SELECT c.state, c.party, SUM(c.total_votes) AS party_votes_2014, c1.state_total
FROM constituency_wise_results_2014 c
JOIN cte c1 ON c.state = c1.state AND c1.year = 2014
GROUP BY c.state, c.party, c1.state_total
),
state_party_2019 AS (
SELECT c.state, c.party, SUM(c.total_votes) AS party_votes_2019, c1.state_total
FROM constituency_wise_results_2019 c
JOIN cte c1 ON c.state = c1.state AND c1.year = 2019
GROUP BY c.state, c.party, c1.state_total
),
combined_years AS (
SELECT COALESCE(s14.state, s19.state) AS state_name, COALESCE(s14.party, s19.party) AS party, 
COALESCE(s14.party_votes_2014, 0) AS votes_2014, COALESCE(s14.state_total, 0) AS state_total_2014,
COALESCE(s19.party_votes_2019, 0) AS votes_2019, COALESCE(s19.state_total, 0) AS state_total_2019
FROM state_party_2014 s14
FULL OUTER JOIN state_party_2019 s19 ON s14.state = s19.state AND s14.party = s19.party
)
SELECT state_name, party, votes_2014, votes_2019,
CONCAT(FORMAT(CASE WHEN state_total_2014 > 0 THEN votes_2014 * 100.0 / state_total_2014 ELSE 0 END, '0.00'), ' %') AS vote_share_2014_pct,
CONCAT(FORMAT(CASE WHEN state_total_2019 > 0 THEN votes_2019 * 100.0 / state_total_2019 ELSE 0 END, '0.00'), ' %') AS vote_share_2019_pct,
CONCAT(FORMAT((CASE WHEN state_total_2019 > 0 THEN votes_2019 * 100.0 / state_total_2019 ELSE 0 END) -
(CASE WHEN state_total_2014 > 0 THEN votes_2014 * 100.0 / state_total_2014 ELSE 0 END), '0.00'), ' %') AS pct_point_change
FROM combined_years;


-- 8. List top 5 constituencies for two major national parties where they have gained vote share in 2019 as compared to 2014.

WITH party_votes_2019_2014 AS (
SELECT party, '2019' AS year, SUM(total_votes) AS party_national_votes
FROM constituency_wise_results_2019
GROUP BY party
UNION ALL
SELECT party, '2014' AS year, SUM(total_votes) AS party_national_votes
FROM constituency_wise_results_2014
GROUP BY party
),
top_party AS (
SELECT *, ROW_NUMBER() OVER(PARTITION BY year ORDER BY party_national_votes DESC) AS rn
FROM party_votes_2019_2014
),
cte1 AS (
SELECT pc_name, party, total_votes AS party_votes_2019, SUM(total_votes) OVER(PARTITION BY pc_name) AS constituency_total_2019, 
total_votes * 100.0 / SUM(total_votes) OVER(PARTITION BY pc_name) AS vote_share
FROM constituency_wise_results_2019 
WHERE party IN (SELECT party FROM top_party WHERE rn <= 2)
),
rank_2019 AS (
SELECT pc_name, party, party_votes_2019, constituency_total_2019, vote_share, DENSE_RANK() OVER(ORDER BY constituency_total_2019 DESC) AS drnk
FROM cte1
),
cte2 AS (
SELECT pc_name, party, total_votes AS party_votes_2014, SUM(total_votes) OVER(PARTITION BY pc_name) AS constituency_total_2014, 
total_votes * 100.0 / SUM(total_votes) OVER(PARTITION BY pc_name) AS vote_share
FROM constituency_wise_results_2014 
WHERE party IN (SELECT party FROM top_party WHERE rn <= 2)
),
rank_2014 AS (
SELECT pc_name, party, party_votes_2014, constituency_total_2014, vote_share, DENSE_RANK() OVER(ORDER BY constituency_total_2014 DESC) AS drnk
FROM cte2
),
top5_constituency_2019 AS (
SELECT pc_name AS constituency_2019, party AS party_2019, vote_share AS vote_share_2019
FROM rank_2019
WHERE drnk <= 5 
),
top5_constituency_2014 AS (
SELECT pc_name AS constituency_2014, party AS party_2014, vote_share AS vote_share_2014
FROM rank_2014
WHERE drnk <= 5 
)
SELECT c19.constituency_2019, c19.party_2019, CONCAT(FORMAT(c19.vote_share_2019, '0.00'), ' %') AS vote_share_2019, 
c14.constituency_2014, c14.party_2014, CONCAT(FORMAT(c14.vote_share_2014, '0.00'), ' %') AS vote_share_2014
FROM top5_constituency_2019 c19
FULL OUTER JOIN top5_constituency_2014 c14 ON c19.constituency_2019 = c14.constituency_2014 AND c19.party_2019 = c14.party_2014
WHERE c19.vote_share_2019 > c14.vote_share_2014
ORDER BY 1;


-- 9. List top 5 constituencies for two major national parties where they have lost vote share in 2019 as compared to 2014.

WITH party_votes_2019_2014 AS (
SELECT party, '2019' AS year, SUM(total_votes) AS party_national_votes
FROM constituency_wise_results_2019
GROUP BY party
UNION ALL
SELECT party, '2014' AS year, SUM(total_votes) AS party_national_votes
FROM constituency_wise_results_2014
GROUP BY party
),
top_party AS (
SELECT *, ROW_NUMBER() OVER(PARTITION BY year ORDER BY party_national_votes DESC) AS rn
FROM party_votes_2019_2014
),
cte1 AS (
SELECT pc_name, party, total_votes AS party_votes_2019, SUM(total_votes) OVER(PARTITION BY pc_name) AS constituency_total_2019, 
total_votes * 100.0 / SUM(total_votes) OVER(PARTITION BY pc_name) AS vote_share
FROM constituency_wise_results_2019 
WHERE party IN (SELECT party FROM top_party WHERE rn <= 2)
),
rank_2019 AS (
SELECT pc_name, party, party_votes_2019, constituency_total_2019, vote_share, DENSE_RANK() OVER(ORDER BY constituency_total_2019 DESC) AS drnk
FROM cte1
),
cte2 AS (
SELECT pc_name, party, total_votes AS party_votes_2014, SUM(total_votes) OVER(PARTITION BY pc_name) AS constituency_total_2014, 
total_votes * 100.0 / SUM(total_votes) OVER(PARTITION BY pc_name) AS vote_share
FROM constituency_wise_results_2014 
WHERE party IN (SELECT party FROM top_party WHERE rn <= 2)
),
rank_2014 AS (
SELECT pc_name, party, party_votes_2014, constituency_total_2014, vote_share, DENSE_RANK() OVER(ORDER BY constituency_total_2014 DESC) AS drnk
FROM cte2
),
top5_constituency_2019 AS (
SELECT pc_name AS constituency_2019, party AS party_2019, vote_share AS vote_share_2019
FROM rank_2019
WHERE drnk <= 5 
),
top5_constituency_2014 AS (
SELECT pc_name AS constituency_2014, party AS party_2014, vote_share AS vote_share_2014
FROM rank_2014
WHERE drnk <= 5 
)
SELECT c19.constituency_2019, c19.party_2019, CONCAT(FORMAT(c19.vote_share_2019, '0.00'), ' %') AS vote_share_2019, 
c14.constituency_2014, c14.party_2014, CONCAT(FORMAT(c14.vote_share_2014, '0.00'), ' %') AS vote_share_2014
FROM top5_constituency_2019 c19
FULL OUTER JOIN top5_constituency_2014 c14 ON c19.constituency_2019 = c14.constituency_2014 AND c19.party_2019 = c14.party_2014
WHERE c19.vote_share_2019 < c14.vote_share_2014
ORDER BY 1;


-- 10. Which constituency has voted the most for NOTA?

WITH cte1 AS (
SELECT pc_name AS constituency_2014, SUM(total_votes) AS total_votes_2014, ROW_NUMBER() OVER(ORDER BY SUM(total_votes) DESC) AS rn1
FROM constituency_wise_results_2014
WHERE candidate = 'NOTA'
GROUP BY pc_name
),
cte2 AS (
SELECT pc_name AS constituency_2019, SUM(total_votes) AS total_votes_2019, ROW_NUMBER() OVER(ORDER BY SUM(total_votes) DESC) AS rn2
FROM constituency_wise_results_2019
WHERE candidate = 'NOTA'
GROUP BY pc_name
)
SELECT cte1.constituency_2014, total_votes_2014, cte2.constituency_2019, total_votes_2019
FROM cte1, cte2
WHERE rn1 = 1 AND rn2 = 1;

-- 11. Which constituencies have elected candidates whose party has less than 10% vote share at state level in 2019?

WITH cte AS (
SELECT state, SUM(total_votes) AS state_total_2019
FROM constituency_wise_results_2019
GROUP BY state
),
state_vote_share_2019 AS (
SELECT c.state, c.party, SUM(c.total_votes) AS party_votes_2019, c1.state_total_2019, 
SUM(c.total_votes) * 100.0 / c1.state_total_2019 AS state_vote_share_pct
FROM constituency_wise_results_2019 c
JOIN cte c1 ON c.state = c1.state
GROUP BY c.state, c.party, c1.state_total_2019
),
constituency_winners_2019 AS (
SELECT state, pc_name, party AS winning_party, total_votes AS winning_votes, 
SUM(total_votes) OVER (PARTITION BY pc_name) AS constituency_total,
total_votes * 100.0 / SUM(total_votes) OVER(PARTITION BY pc_name) AS winning_vote_share_pct,
ROW_NUMBER() OVER (PARTITION BY pc_name ORDER BY total_votes DESC) AS win_rank
FROM constituency_wise_results_2019 
)
SELECT cw.pc_name AS constituency, cw.state, cw.winning_party, cw.winning_votes, cw.constituency_total, 
CONCAT(FORMAT(cw.winning_vote_share_pct, '0.00'), ' %') AS constituency_win_share_pct, 
CONCAT(FORMAT(svs.state_vote_share_pct, '0.00'), ' %') AS state_party_share_pct, svs.party_votes_2019,
svs.state_total_2019, CONCAT(FORMAT(cw.winning_vote_share_pct - svs.state_vote_share_pct, '0.00'), ' %') AS performance_gap
FROM constituency_winners_2019 cw
JOIN state_vote_share_2019 svs ON cw.state = svs.state AND cw.winning_party = svs.party
WHERE cw.win_rank = 1 AND svs.state_vote_share_pct < 10 AND cw.winning_vote_share_pct > svs.state_vote_share_pct;
