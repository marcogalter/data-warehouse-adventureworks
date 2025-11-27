-- Inserir dados de exemplo no AdventureWorks
-- Este script popula o banco com dados mínimos para teste

-- Categorias de Produto
INSERT INTO production.productcategory (productcategoryid, name) VALUES
(1, 'Bikes'), (2, 'Components'), (3, 'Clothing'), (4, 'Accessories')
ON CONFLICT DO NOTHING;

-- Subcategorias
INSERT INTO production.productsubcategory (productsubcategoryid, productcategoryid, name) VALUES
(1, 1, 'Mountain Bikes'), (2, 1, 'Road Bikes'), (3, 1, 'Touring Bikes'),
(4, 2, 'Handlebars'), (5, 3, 'Jerseys'), (6, 4, 'Helmets')
ON CONFLICT DO NOTHING;

-- Produtos
INSERT INTO production.product (productid, name, productnumber, color, listprice, standardcost, productsubcategoryid)
SELECT gs.id,
       'Product ' || gs.id,
       'PR-' || LPAD(gs.id::text, 4, '0'),
       CASE (gs.id % 5) WHEN 0 THEN 'Red' WHEN 1 THEN 'Blue' WHEN 2 THEN 'Black' WHEN 3 THEN 'Silver' ELSE 'White' END,
       (RANDOM() * 1000 + 100)::numeric(19,4),
       (RANDOM() * 500 + 50)::numeric(19,4),
       ((gs.id % 6) + 1)
FROM generate_series(1, 500) gs(id)
ON CONFLICT DO NOTHING;

-- Territórios
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
(10, 'United Kingdom', 'GB', 'Europe')
ON CONFLICT DO NOTHING;

-- Pessoas (para clientes e vendedores)
INSERT INTO person.person (businessentityid, persontype, firstname, lastname)
SELECT gs.id, 
       CASE WHEN gs.id <= 20 THEN 'SP' ELSE 'IN' END,
       'FirstName' || gs.id,
       'LastName' || gs.id
FROM generate_series(1, 20000) gs(id)
ON CONFLICT DO NOTHING;

-- Lojas
INSERT INTO sales.store (businessentityid, name)
SELECT gs.id + 20000,
       'Store ' || gs.id
FROM generate_series(1, 700) gs(id)
ON CONFLICT DO NOTHING;

-- Clientes
INSERT INTO sales.customer (customerid, personid, storeid, territoryid)
SELECT gs.id,
       CASE WHEN gs.id <= 19000 THEN gs.id ELSE NULL END,
       CASE WHEN gs.id > 19000 THEN (gs.id - 19000 + 20000) ELSE NULL END,
       ((gs.id % 10) + 1)
FROM generate_series(1, 19700) gs(id)
ON CONFLICT DO NOTHING;

-- Funcionários
INSERT INTO humanresources.employee (businessentityid, jobtitle, birthdate, hiredate, gender, maritalstatus)
SELECT gs.id,
       CASE (gs.id % 3) WHEN 0 THEN 'Sales Representative' WHEN 1 THEN 'Sales Manager' ELSE 'Sales Lead' END,
       '1980-01-01'::date + (gs.id || ' days')::interval,
       '2010-01-01'::date,
       CASE WHEN gs.id % 2 = 0 THEN 'M' ELSE 'F' END,
       CASE WHEN gs.id % 2 = 0 THEN 'M' ELSE 'S' END
FROM generate_series(1, 20) gs(id)
ON CONFLICT DO NOTHING;

-- Vendedores (apenas para funcionários que existem)
INSERT INTO sales.salesperson (businessentityid, territoryid, salesquota, bonus, commissionpct)
SELECT gs.id,
       ((gs.id % 10) + 1),
       250000,
       0,
       0.01
FROM generate_series(1, 17) gs(id)
WHERE EXISTS (SELECT 1 FROM humanresources.employee WHERE businessentityid = gs.id)
ON CONFLICT DO NOTHING;

-- Métodos de Envio
INSERT INTO purchasing.shipmethod (shipmethodid, name, shipbase, shiprate) VALUES
(1, 'CARGO TRANSPORT 5', 8.99, 0.99),
(2, 'OVERNIGHT J-FAST', 21.95, 1.29),
(3, 'OVERSEAS - DELUXE', 29.95, 1.49),
(4, 'XRQ - TRUCK GROUND', 3.95, 0.79),
(5, 'ZY - EXPRESS', 11.99, 1.09)
ON CONFLICT DO NOTHING;

-- Pedidos de Venda (cabeçalho)
INSERT INTO sales.salesorderheader (salesorderid, orderdate, duedate, shipdate, status, onlineorderflag, customerid, salespersonid, territoryid, shipmethodid, subtotal, taxamt, freight, totaldue)
SELECT gs.id,
       ('2011-01-01'::date + ((gs.id % 1460) || ' days')::interval)::timestamp,
       ('2011-01-01'::date + (((gs.id % 1460) + 7) || ' days')::interval)::timestamp,
       ('2011-01-01'::date + (((gs.id % 1460) + 3) || ' days')::interval)::timestamp,
       5,
       (gs.id % 2 = 0),
       ((gs.id % 19700) + 1),
       CASE WHEN gs.id % 3 = 0 THEN ((gs.id % 17) + 1) ELSE NULL END,
       ((gs.id % 10) + 1),
       ((gs.id % 5) + 1),
       (RANDOM() * 5000 + 100)::numeric(19,4),
       (RANDOM() * 500 + 10)::numeric(19,4),
       (RANDOM() * 100 + 5)::numeric(19,4),
       0
FROM generate_series(1, 31000) gs(id)
ON CONFLICT DO NOTHING;

-- Atualizar totaldue
UPDATE sales.salesorderheader SET totaldue = subtotal + taxamt + freight;

-- Detalhes dos Pedidos
INSERT INTO sales.salesorderdetail (salesorderid, salesorderdetailid, orderqty, productid, specialofferid, unitprice, unitpricediscount)
SELECT soh.salesorderid,
       row_number() OVER (PARTITION BY soh.salesorderid ORDER BY random()),
       (RANDOM() * 10 + 1)::int,
       ((RANDOM() * 499)::int + 1),
       1,
       (RANDOM() * 1000 + 50)::numeric(19,4),
       CASE WHEN RANDOM() > 0.7 THEN (RANDOM() * 0.2)::numeric(19,4) ELSE 0 END
FROM sales.salesorderheader soh,
     generate_series(1, (RANDOM() * 5 + 1)::int) items
ON CONFLICT DO NOTHING;

-- Special Offer
INSERT INTO sales.specialofferproduct (specialofferid, productid)
SELECT 1, productid FROM production.product
ON CONFLICT DO NOTHING;

INSERT INTO sales.specialoffer (specialofferid, description, discountpct, type, category, startdate, enddate) 
VALUES (1, 'No Discount', 0, 'No Discount', 'No Discount', '2011-01-01', '2014-12-31')
ON CONFLICT DO NOTHING;

-- Mensagem final
SELECT 'Dados inseridos com sucesso!' as status,
       (SELECT COUNT(*) FROM production.product) as produtos,
       (SELECT COUNT(*) FROM sales.customer) as clientes,
       (SELECT COUNT(*) FROM sales.salesorderheader) as pedidos,
       (SELECT COUNT(*) FROM sales.salesorderdetail) as itens_pedido;
