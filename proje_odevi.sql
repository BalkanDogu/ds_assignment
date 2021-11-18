

--- SQL PROJE ODEVI 

-- not 1 : format deðiþikliði yapýp dosyalarý yüklemek iki gün sürdü yani ödeve baþlama süresi iki gün 

-- not 2 : hocam ben sizin bu sql dosyanýzý görmedim odevi yaparken bitirmek üzereyken farkettim o 
-- o yüzden sizin þunu kullanýn bunu kullanýn dediðiniz þeylerle yapýlmamýþ olabilir sorular ama 
-- bu benim duþunup bulmam için daha iyi oldu.

/* Tüm tablolara katýlýn ve tüm sütunlarla birleþtirilmiþ_tablo adý verilen yeni bir tablo oluþturun. 
(market_fact, cust_dimen, order_dimen, prod_dimen, shipping_dimen) */


DROP TABLE IF EXISTS combined_table

SELECT * INTO combined_table
FROM(SELECT A.Cust_id, A.Discount, A.Ord_id,A.Order_Quantity,A.Prod_id,A.Product_Base_Margin,A.Sales,A.Ship_id,
			B.Customer_Name,B.Customer_Segment,B.Province,B.Region,
			C.Order_Date,C.Order_Priority,
			D.Product_Category,D.Product_Sub_Category,
			E.Ship_Date,E.Ship_Mode,E.Order_ID
	 FROM dbo.market_fact A
			INNER JOIN dbo.cust_dimen B ON A.Cust_id = B.Cust_id
			INNER JOIN dbo.orders_dimen C ON A.Ord_id = C.Ord_id
			INNER JOIN dbo.prod_dimen D ON A.Prod_id = D.Prod_id
			INNER JOIN dbo.shipping_dimen E ON A.Ship_id = E.Ship_id) A



-- Result of Q-2:
-- Maksimum sipariþ sayýsýna sahip ilk 3 müþteriyi bulun.

SELECT TOP 3 Cust_id, COUNT(ord_id) count_of_orders
FROM market_fact
GROUP BY Cust_id
ORDER BY COUNT(ord_id) DESC


-- Result of Q-3:
--Kombine_tabloda, Sipariþ_Tarihi ve Sevk_Tarihi arasýndaki tarih farkýný içeren DaysTakenForDelivery 
--olarak yeni bir sütun oluþturun.

ALTER TABLE dbo.combined_table
ADD DaysTakenForDelivery int;

UPDATE dbo.combined_table
SET DaysTakenForDelivery = DATEDIFF(DAY, Order_Date, Ship_Date);

SELECT *
FROM dbo.combined_table

-- Result of Q-4:

--Sipariþinin teslim edilmesi için maksimum süreyi alan müþteriyi bulun.

SELECT TOP 1 Cust_id, Customer_Name,Order_Date,Ship_Date, DaysTakenForDelivery
FROM dbo.combined_table
ORDER BY DaysTakenForDelivery DESC

-- Result of Q-5:
--Ocak ayýndaki toplam benzersiz müþteri sayýsýný ve 2011'de tüm yýl boyunca kaç tanesinin 
--her ay geri geldiðini sayýn.

SELECT MONTH(A.Order_Date) MONTH, COUNT(DISTINCT B.Cust_id)MOUNTHLY_NUM_OF_CUST
FROM orders_dimen A, market_fact B
WHERE A.Ord_id = B.Ord_id
AND YEAR(Order_Date) = 2011
AND B.Cust_id IN(
					SELECT B.Cust_id
					FROM orders_dimen A, market_fact B
					WHERE A.Ord_id = B.Ord_id
					AND MONTH(Order_Date) = 1
					AND YEAR(Order_Date) = 2011
					GROUP BY B.Cust_id)
GROUP BY MONTH(A.Order_Date)


-- Result of Q-6:
-- Her kullanýcý için ilk satýn alma ile üçüncü satýn alma arasýnda geçen süreyi Müþteri Kimliðine göre 
-- artan sýrada döndürecek bir sorgu yazýn.


WITH T1 AS(
SELECT Cust_id, Order_Date,
DENSE_RANK() OVER(PARTITION BY Cust_id ORDER BY Order_Date) DENSE_NUMBER,
MIN(Order_Date) OVER(PARTITION BY Cust_id ORDER BY Order_Date) FIRST_ORDER_DATE
FROM combined_table)

SELECT DISTINCT Cust_id, Order_Date, DENSE_NUMBER, FIRST_ORDER_DATE,
DATEDIFF(DAY, FIRST_ORDER_DATE, Order_Date)DAYS_ELAPSED
FROM T1
WHERE dense_number = 3
ORDER BY Cust_id ASC


-- Result of Q-7:
--Hem 11. ürünü hem de 14. ürünü satýn alan müþterileri ve bu ürünlerin müþteri tarafýndan satýn alýnan 
--toplam ürün sayýsýna oranýný veren bir sorgu yazýn.

WITH T1 AS(
SELECT Cust_id,
	SUM(CASE WHEN Prod_id = 'Prod_11' THEN 1*Order_Quantity ELSE 0 END)P11,
	SUM(CASE WHEN Prod_id = 'Prod_14' THEN 1*Order_Quantity ELSE 0 END)P14,
	SUM(CASE WHEN Prod_id IS NOT NULL THEN 1*Order_Quantity ELSE 0 END)TOTAL_PROD
FROM dbo.combined_table
GROUP BY Cust_id
HAVING
		SUM(CASE WHEN Prod_id = 'Prod_11' THEN 1 ELSE 0 END) >= 1
AND		SUM(CASE WHEN Prod_id = 'Prod_14' THEN 1 ELSE 0 END) >= 1)

SELECT Cust_id, P11, P14, TOTAL_PROD,
CAST(ROUND(AVG(P11/TOTAL_PROD) OVER(),3) AS DECIMAL(16,2))RATIO_P11,
CAST(ROUND(AVG(P14/TOTAL_PROD) OVER(),3) AS DECIMAL(16,2))RATIO_P14
FROM T1


--Customer Segmentation

-- Result of Q-1:
-- Müþterilerin ziyaret günlüklerini aylýk olarak tutan bir görünüm oluþturun. 
-- (Her log için üç alan tutulur: Cust_id, Year, Month)

CREATE VIEW cus_viz_monthly
AS
SELECT Cust_id,
YEAR(Order_Date)YEAR, MONTH(Order_Date)MONTH
FROM dbo.combined_table

SELECT *
FROM cus_viz_monthly
ORDER BY Cust_id


-- Result of Q-2:
-- Kullanýcýlarýn aylýk ziyaretlerinin sayýsýný tutan bir görünüm oluþturun. 
-- (Ýþ baþlangýcýndan itibaren tüm aylar için ayrý ayrý)

CREATE VIEW NUM_OF_LOG
AS
SELECT Cust_id, YEAR, MONTH, COUNT(*)NUM_OF_LOG
FROM cus_viz_monthly
GROUP BY Cust_id,YEAR, MONTH

SELECT *
FROM NUM_OF_LOG
ORDER BY 1

-- Result of Q-3:
-- Müþterilerin her ziyareti için, ziyaretin bir sonraki ayýný ayrý bir sütun olarak oluþturun.


CREATE VIEW NEXT_VISIT AS
SELECT *,
        LEAD(CURRENT_MONTH, 1) OVER (PARTITION BY Cust_id ORDER BY CURRENT_MONTH) NEXT_VISIT_MONTH
FROM
(SELECT  *,
        DENSE_RANK () OVER (ORDER BY [YEAR] , [MONTH]) CURRENT_MONTH
FROM    NUM_OF_LOG) A



-- Result of Q-4:
-- Her müþterinin birbirini takip eden iki ziyareti arasýndaki aylýk zaman aralýðýný hesaplayýn.

WITH T1 AS(
SELECT DISTINCT Cust_id,
AVG(NEXT_VISIT_MONTH - CURRENT_MONTH) OVER(PARTITION BY Cust_id)AVG_TIME_GAP
FROM NEXT_VISIT)

SELECT Cust_id, AVG_TIME_GAP,
CASE WHEN AVG_TIME_GAP IS NULL THEN 'Churn'
     WHEN AVG_TIME_GAP > 0 THEN 'irregular' END AS CUST_LABELS
FROM T1

-- Result of Q-5:
-- Ortalama zaman boþluklarýný kullanarak müþterileri kategorilere ayýrýn. Size en uygun etiketleme modelini seçin.

CREATE VIEW TIME_GAP AS
SELECT Cust_id, YEAR, MONTH, NUM_OF_LOG, CURRENT_MONTH, NEXT_VISIT_MONTH,
NEXT_VISIT_MONTH - CURRENT_MONTH TIME_GAPS
FROM NEXT_VISIT


--MONTH-WÝSE RETENTÝON RATE


--Find month-by-month customer retention rate  since the start of the business.

-- Result of Q-1:
--1. Find the number of customers retained month-wise. (You can use time gaps)
--Use Time Gaps

-- Ay bazýnda elde tutulan müþteri sayýsýný bulun. (Zaman boþluklarýný kullanabilirsiniz)

CREATE VIEW RETENTION_MONTH AS
SELECT *,
COUNT(Cust_id) OVER (PARTITION BY CURRENT_MONTH)RETENTION_MONTH_WISE
FROM TIME_GAP
WHERE TIME_GAPS = 1

SELECT *
FROM RETENTION_MONTH
ORDER BY 1


-- Result of Q-2:
-- Ay bazýnda elde tutma oranýný hesaplayýn.
-- o Ay Bazýnda Elde Tutma Oraný = 1.0 * Önceki Aydaki Toplam Müþteri Sayýsý / Sonraki Ayda Elde Tutulan Müþteri Sayýsý

CREATE VIEW Next_Month AS

SELECT YEAR, MONTH, COUNT(Cust_id) Cus_month,
LAG(COUNT(Cust_id),1) OVER(ORDER BY YEAR) Next_Month_Cus
FROM TIME_GAP
GROUP BY YEAR, MONTH


SELECT A.YEAR, A.MONTH,
LAG(CAST(ROUND(AVG(1.0*B.RETENTION_MONTH_WISE/A.Cus_month),2) AS DECIMAL(16,2)),1) OVER (ORDER BY A.MONTH)RETENTION_RATE 
FROM Next_Month A, RETENTION_MONTH B
WHERE A.YEAR = B.YEAR
GROUP BY A.YEAR, A.MONTH
ORDER BY YEAR, MONTH




