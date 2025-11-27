-- Dados mínimos simplificados para AdventureWorks
-- Ignora FKs complexas, insere dados direto nas tabelas principais

-- 1. PRODUTOS
TRUNCATE production.product CASCADE;
INSERT INTO production.product (productid, name, productnumber, color, listprice, standardcost, productsubcategoryid, safetystocklevel, reorderpoint, daystomanufacture, sellstartdate)
SELECT gs.id,
       'Product-' || gs.id,
       'PR-' || LPAD(gs.id::text, 4, '0'),
       CASE (gs.id % 5) WHEN 0 THEN 'Red' WHEN 1 THEN 'Blue' WHEN 2 THEN 'Black' WHEN 3 THEN 'Silver' ELSE 'White' END,
       (500 + (gs.id * 10))::numeric(19,4),
       (250 + (gs.id * 5))::numeric(19,4),
       NULL,
       1000,
       750,
       0,
       '2010-01-01'::date
FROM generate_series(1, 504) gs(id);

-- 2. TERRIT�RIOS
TRUNCATE sales.salesterritory CASCADE;
INSERT INTO sales.salesterritory (territoryid, name, countryregioncode, "group") VALUES
(1, 'Northwest', 'US', 'North America'),
(2, 'Northeast', 'US', 'North America'),
(3, 'Central', 'US', 'North America'),
(4, 'Southwest', 'US', 'North America'),
(5, 'Southeast', 'US', 'North America'),
(6, 'Canada', 'CA', 'North America'),
(7, 'France', 'FR', 'Europe'),
(8, 'Germany', 'DE', 'Europe'),
(9, 'Australia', 'AU', 'Pacific'),
(10, 'United Kingdom', 'GB', 'Europe');

-- 3. CLIENTES (simplificado - SEM person/store)
TRUNCATE sales.customer CASCADE;
INSERT INTO sales.customer (customerid, personid, storeid, territoryid, accountnumber)
SELECT gs.id,
       NULL,
       NULL,
       ((gs.id % 10) + 1),
       'AW' || LPAD(gs.id::text, 8, '0')
FROM generate_series(1, 19820) gs(id);

-- 4. VENDEDORES (simplificado - SEM employee/person)
TRUNCATE sales.salesperson CASCADE;
INSERT INTO sales.salesperson (businessentityid, territoryid, salesquota, bonus, commissionpct, salesytd, saleslastyear)
SELECT gs.id,
       ((gs.id % 10) + 1),
       250000,
       0,
       0.012,
       0,
       0
FROM generate_series(1, 17) gs(id);

-- 5. M�TODOS DE ENVIO
TRUNCATE purchasing.shipmethod CASCADE;
INSERT INTO purchasing.shipmethod (shipmethodid, name, shipbase, shiprate) VALUES
(1, 'CARGO TRANSPORT 5', 8.99, 0.99),
(2, 'OVERNIGHT J-FAST', 21.95, 1.29),
(3, 'OVERSEAS - DELUXE', 29.95, 1.49),
(4, 'XRQ - TRUCK GROUND', 3.95, 0.79),
(5, 'ZY - EXPRESS', 11.99, 1.09);

-- 6. ENDERE�OS (m�nimo para salesorderheader)
TRUNCATE person.address CASCADE;
INSERT INTO person.address (addressid, addressline1, city, stateprovinceid, postalcode)
SELECT gs.id,
       '123 Main St #' || gs.id,
       'City' || (gs.id % 50),
       79, -- default state
       LPAD((gs.id % 99999)::text, 5, '0')
FROM generate_series(1, 100) gs(id);

-- 7. PEDIDOS (cabeçalho)
TRUNCATE sales.salesorderheader CASCADE;
INSERT INTO sales.salesorderheader (
    salesorderid, revisionnumber, orderdate, duedate, shipdate, status, onlineorderflag,
    customerid, salespersonid, territoryid, billtoaddressid, shiptoaddressid, shipmethodid,
    subtotal, taxamt, freight, totaldue
)
SELECT gs.id,
       1,
       ('2011-01-01'::date + ((gs.id % 1460) || ' days')::interval)::timestamp,
       ('2011-01-01'::date + (((gs.id % 1460) + 7) || ' days')::interval)::timestamp,
       ('2011-01-01'::date + (((gs.id % 1460) + 3) || ' days')::interval)::timestamp,
       5,
       (gs.id % 2 = 0),
       ((gs.id % 19820) + 1),
       CASE WHEN gs.id % 3 = 0 THEN ((gs.id % 17) + 1) ELSE NULL END,
       ((gs.id % 10) + 1),
       ((gs.id % 100) + 1),
       ((gs.id % 100) + 1),
       ((gs.id % 5) + 1),
       (2000 + (gs.id * 3.5))::numeric(19,4),
       (200 + (gs.id * 0.35))::numeric(19,4),
       (50 + (gs.id * 0.1))::numeric(19,4),
       0
FROM generate_series(1, 31465) gs(id);

-- Atualizar totaldue
UPDATE sales.salesorderheader SET totaldue = subtotal + taxamt + freight;

-- 8. SPECIAL OFFER (necessário para salesorderdetail)
TRUNCATE sales.specialoffer CASCADE;
INSERT INTO sales.specialoffer (specialofferid, description, discountpct, type, category, startdate, enddate, minqty) 
VALUES (1, 'No Discount', 0, 'No Discount', 'No Discount', '2011-01-01', '2014-12-31', 0);

TRUNCATE sales.specialofferproduct CASCADE;
INSERT INTO sales.specialofferproduct (specialofferid, productid)
SELECT 1, productid FROM production.product;

-- 9. DETALHES DOS PEDIDOS
TRUNCATE sales.salesorderdetail CASCADE;
INSERT INTO sales.salesorderdetail (salesorderid, salesorderdetailid, orderqty, productid, specialofferid, unitprice, unitpricediscount)
SELECT soh.salesorderid,
       row_number() OVER (PARTITION BY soh.salesorderid ORDER BY random())::int,
       (1 + (random() * 10)::int),
       (1 + (random() * 503)::int),
       1,
       (100 + (random() * 900))::numeric(19,4),
       CASE WHEN random() > 0.7 THEN (random() * 0.15)::numeric(19,4) ELSE 0 END
FROM sales.salesorderheader soh
CROSS JOIN generate_series(1, (1 + (random() * 4)::int)) items(n)
WHERE soh.salesorderid <= 31465;

-- Estatísticas finais
SELECT 'Dados carregados com sucesso!' as status,
       (SELECT COUNT(*) FROM production.product) as produtos,
       (SELECT COUNT(*) FROM sales.customer) as clientes,
       (SELECT COUNT(*) FROM sales.salesterritory) as territorios,
       (SELECT COUNT(*) FROM sales.salesperson) as vendedores,
       (SELECT COUNT(*) FROM purchasing.shipmethod) as metodos_envio,
       (SELECT COUNT(*) FROM sales.salesorderheader) as pedidos,
       (SELECT COUNT(*) FROM sales.salesorderdetail) as itens_pedido;
