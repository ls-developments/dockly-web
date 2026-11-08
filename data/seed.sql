-- Dockly · Fort Lauderdale: muelles iniciales, parámetros de precio en dólares y tarifas fijas.
-- Coordenadas de OpenStreetMap (marinas y paradas del Water Taxi) del 8 de noviembre de 2026.
-- Antes de salir a producción: confirmar con Martín qué muelles permiten embarcar chárteres.
-- Volver a correr es seguro (upsert por id y por par de muelles).

insert into docks (id, name, river, type, location, description, is_public) values
 ('10000000-0000-0000-0000-000000000001','Las Olas Marina · Water Taxi','Intracoastal','terminal', st_setsrid(st_makepoint(-80.1083,26.1187),4326), 'Main hub at Las Olas Blvd and the Intracoastal, next to Beach Place.', true),
 ('10000000-0000-0000-0000-000000000002','Riverwalk · Esplanade Park','New River','public', st_setsrid(st_makepoint(-80.14842,26.11926),4326), 'Public docks on the Riverwalk, by the Museum of Discovery.', true),
 ('10000000-0000-0000-0000-000000000003','Riverside Hotel · Stranahan House','New River','recreo', st_setsrid(st_makepoint(-80.13731,26.11826),4326), 'Downtown Las Olas. Dock in front of the Riverside Hotel.', true),
 ('10000000-0000-0000-0000-000000000004','The Historic Downtowner Saloon','New River','recreo', st_setsrid(st_makepoint(-80.14283,26.11769),4326), 'Restaurant dock, south bank by the Andrews Ave bridge.', true),
 ('10000000-0000-0000-0000-000000000005','Pirate Republic Bar','New River','recreo', st_setsrid(st_makepoint(-80.14621,26.11834),4326), 'Restaurant dock on the north bank.', true),
 ('10000000-0000-0000-0000-000000000006','Brightline Station · Briny Irish Pub','New River','public', st_setsrid(st_makepoint(-80.14498,26.11877),4326), 'Closest dock to the Brightline train station.', true),
 ('10000000-0000-0000-0000-000000000007','Shops at Las Olas','Las Olas Isles','comercio', st_setsrid(st_makepoint(-80.13403,26.11787),4326), 'Water Taxi stop on the Las Olas canals.', true),
 ('10000000-0000-0000-0000-000000000008','Bahia Mar Yachting Center','Intracoastal','privado', st_setsrid(st_makepoint(-80.1076,26.11174),4326), 'Marina. Check in at the dockmaster.', true),
 ('10000000-0000-0000-0000-000000000009','Pier Sixty-Six Marina','Intracoastal','privado', st_setsrid(st_makepoint(-80.11715,26.10184),4326), 'Marina south of the 17th St bridge.', true),
 ('10000000-0000-0000-0000-000000000010','Hilton Marina · Convention Center','Intracoastal','terminal', st_setsrid(st_makepoint(-80.1193,26.10078),4326), 'Water Taxi stop next to the Convention Center.', true),
 ('10000000-0000-0000-0000-000000000011','15th Street Fisheries','Intracoastal','recreo', st_setsrid(st_makepoint(-80.11982,26.103),4326), 'Restaurant dock at Lauderdale Marina.', true),
 ('10000000-0000-0000-0000-000000000012','Port Everglades · Terminal 21','Port Everglades','terminal', st_setsrid(st_makepoint(-80.11607,26.08802),4326), 'Cruise terminal 21. Security checks apply.', true),
 ('10000000-0000-0000-0000-000000000013','Hugh Taylor Birch State Park','Intracoastal','public', st_setsrid(st_makepoint(-80.10665,26.14293),4326), 'Park dock on the Intracoastal, west side.', true),
 ('10000000-0000-0000-0000-000000000014','Gallery ONE · Galleria','Intracoastal','public', st_setsrid(st_makepoint(-80.10888,26.13726),4326), 'Water Taxi stop by the Galleria mall and Sunrise Blvd.', true),
 ('10000000-0000-0000-0000-000000000015','Coral Ridge Yacht Club','Middle River','privado', st_setsrid(st_makepoint(-80.10858,26.14078),4326), 'Members and guests. Call ahead.', true),
 ('10000000-0000-0000-0000-000000000016','Shooters Waterfront','Middle River','recreo', st_setsrid(st_makepoint(-80.1038,26.16613),4326), 'Restaurant dock on the Intracoastal, Oakland Park Blvd.', true),
 ('10000000-0000-0000-0000-000000000017','Bokamper''s Sports Bar','Middle River','recreo', st_setsrid(st_makepoint(-80.10361,26.16867),4326), 'Restaurant dock just north of Shooters.', true),
 ('10000000-0000-0000-0000-000000000018','Lauderdale Marina','Intracoastal','privado', st_setsrid(st_makepoint(-80.12013,26.10346),4326), 'Fuel dock and marina at 15th St.', true)
on conflict (id) do update set name = excluded.name, river = excluded.river, type = excluded.type, location = excluded.location, description = excluded.description, is_public = excluded.is_public;

-- Parámetros de precio en dólares (enteros = USD). Base 25 + 5 por km (≈ 8 por milla).
update pricing_params set
  base_fare = 25, per_km = 5, large_extra = 20, cargo_extra = 10,
  weekend_pct = 10, driver_adjust_pct = 15, commission_pct = 20, water_factor = 1.35,
  free_wait_min = 10, wait_fee_per_5min = 5,
  quote_window_sec = 180, accept_window_sec = 30,
  op_open_hour = 7, op_close_hour = 23,
  updated_at = now()
where id = 1;

-- Tarifas fijas entre los puntos principales. Precio = 25 + 5·km redondeado a 5 USD; lancha grande +20.
-- Km: ruta por agua si el grafo la encuentra, si no la recta × 1,35. Minutos a 9 nudos (≈17 km/h) + 3 de maniobra.
with pares(a, b) as (values
 ('10000000-0000-0000-0000-000000000001'::uuid,'10000000-0000-0000-0000-000000000002'::uuid),
 ('10000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000003'),
 ('10000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000008'),
 ('10000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000009'),
 ('10000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000010'),
 ('10000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000011'),
 ('10000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000012'),
 ('10000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000013'),
 ('10000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000014'),
 ('10000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000016'),
 ('10000000-0000-0000-0000-000000000002','10000000-0000-0000-0000-000000000003'),
 ('10000000-0000-0000-0000-000000000002','10000000-0000-0000-0000-000000000010'),
 ('10000000-0000-0000-0000-000000000002','10000000-0000-0000-0000-000000000011'),
 ('10000000-0000-0000-0000-000000000003','10000000-0000-0000-0000-000000000010'),
 ('10000000-0000-0000-0000-000000000003','10000000-0000-0000-0000-000000000008'),
 ('10000000-0000-0000-0000-000000000006','10000000-0000-0000-0000-000000000003'),
 ('10000000-0000-0000-0000-000000000006','10000000-0000-0000-0000-000000000010'),
 ('10000000-0000-0000-0000-000000000010','10000000-0000-0000-0000-000000000012'),
 ('10000000-0000-0000-0000-000000000010','10000000-0000-0000-0000-000000000008'),
 ('10000000-0000-0000-0000-000000000011','10000000-0000-0000-0000-000000000009'),
 ('10000000-0000-0000-0000-000000000014','10000000-0000-0000-0000-000000000016'),
 ('10000000-0000-0000-0000-000000000016','10000000-0000-0000-0000-000000000017')
), km as (
  select p.a, p.b,
    round(estimate_water_km(da.location, db.location)::numeric, 1) as km
  from pares p join docks da on da.id = p.a join docks db on db.id = p.b
)
insert into fares (dock_a, dock_b, price_standard, price_large, km_water, est_minutes)
select a, b,
  greatest(20, round((25 + 5 * km) / 5) * 5)::int,
  greatest(20, round((25 + 5 * km) / 5) * 5)::int + 20,
  km,
  greatest(5, round(km / 17 * 60) + 3)::int
from km
on conflict (least(dock_a, dock_b), greatest(dock_a, dock_b)) do update
  set price_standard = excluded.price_standard, price_large = excluded.price_large, km_water = excluded.km_water, est_minutes = excluded.est_minutes;
