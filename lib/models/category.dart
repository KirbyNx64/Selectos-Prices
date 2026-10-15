import 'package:flutter/material.dart';

class SubcategoryItem {
  final String id;
  final String nombre;

  const SubcategoryItem({
    required this.id,
    required this.nombre,
  });
}

class CategoryGroup {
  final String id;
  final String nombre;
  final List<SubcategoryItem> subcategorias;

  const CategoryGroup({
    required this.id,
    required this.nombre,
    this.subcategorias = const [],
  });
}

class MainCategory {
  final String id;
  final String nombre;
  final String tituloCompleto;
  final IconData icon;
  final List<CategoryGroup> grupos;

  const MainCategory({
    required this.id,
    required this.nombre,
    required this.tituloCompleto,
    required this.icon,
    this.grupos = const [],
  });
}

/// Catálogo oficial de categorías y subcategorías de Súper Selectos
final List<MainCategory> listaCategoriasPrincipales = [
  const MainCategory(
    id: '01',
    nombre: 'Productos\nfrescos',
    tituloCompleto: 'Productos frescos',
    icon: Icons.eco_rounded,
    grupos: [
      CategoryGroup(
        id: '018',
        nombre: 'Alimentos preparados',
        subcategorias: [
          SubcategoryItem(id: '01846', nombre: 'Alimentos listos para calentar'),
          SubcategoryItem(id: '01845', nombre: 'Alimentos listos para comer'),
        ],
      ),
      CategoryGroup(
        id: '019',
        nombre: 'Ensaladas y encurtidos',
        subcategorias: [
          SubcategoryItem(id: '01948', nombre: 'Encurtidos'),
          SubcategoryItem(id: '01947', nombre: 'Ensaladas'),
        ],
      ),
      CategoryGroup(
        id: '014',
        nombre: 'Mariscos y pescado',
        subcategorias: [
          SubcategoryItem(id: '01424', nombre: 'Congelados'),
          SubcategoryItem(id: '01423', nombre: 'Frescos'),
          SubcategoryItem(id: '01425', nombre: 'Secos'),
        ],
      ),
      CategoryGroup(
        id: '017',
        nombre: 'Panadería',
        subcategorias: [
          SubcategoryItem(id: '01741', nombre: 'Café bakery'),
          SubcategoryItem(id: '01738', nombre: 'Levadura'),
          SubcategoryItem(id: '01743', nombre: 'Pan dulce'),
          SubcategoryItem(id: '01742', nombre: 'Pan salado'),
          SubcategoryItem(id: '01739', nombre: 'Pasteles y pies'),
          SubcategoryItem(id: '01744', nombre: 'Repostería'),
          SubcategoryItem(id: '01740', nombre: 'Tortas'),
        ],
      ),
      CategoryGroup(
        id: '011',
        nombre: 'Carnes',
        subcategorias: [
          SubcategoryItem(id: '0114', nombre: 'Carne de cerdo'),
          SubcategoryItem(id: '0111', nombre: 'Carne de res'),
          SubcategoryItem(id: '0115', nombre: 'Otras carnes'),
          SubcategoryItem(id: '0113', nombre: 'Pavos'),
          SubcategoryItem(id: '0112', nombre: 'Pollos'),
        ],
      ),
      CategoryGroup(
        id: '012',
        nombre: 'Frutas y verduras',
        subcategorias: [
          SubcategoryItem(id: '01210', nombre: 'Carbón y accesorios agrícolas'),
          SubcategoryItem(id: '0128', nombre: 'Desinfectantes'),
          SubcategoryItem(id: '0129', nombre: 'Dulces variedad'),
          SubcategoryItem(id: '01212', nombre: 'Especias naturales'),
          SubcategoryItem(id: '0126', nombre: 'Frutas'),
          SubcategoryItem(id: '01216', nombre: 'Semillas y comestibles a granel'),
          SubcategoryItem(id: '0127', nombre: 'Verduras'),
          SubcategoryItem(id: '01211', nombre: 'Vinagre casero'),
          SubcategoryItem(id: '01215', nombre: 'Viveros'),
        ],
      ),
      CategoryGroup(
        id: '013',
        nombre: 'Embutidos',
        subcategorias: [
          SubcategoryItem(id: '01322', nombre: 'Chorizos'),
          SubcategoryItem(id: '01317', nombre: 'Jamones'),
          SubcategoryItem(id: '01318', nombre: 'Mortadelas'),
          SubcategoryItem(id: '01320', nombre: 'Salamis'),
          SubcategoryItem(id: '01319', nombre: 'Salchichas'),
          SubcategoryItem(id: '01321', nombre: 'Tocino'),
        ],
      ),
      CategoryGroup(
        id: '015',
        nombre: 'Lácteos y huevos',
        subcategorias: [
          SubcategoryItem(id: '01533', nombre: 'Bebidas de soya y almendra'),
          SubcategoryItem(id: '01526', nombre: 'Crema láctea'),
          SubcategoryItem(id: '01527', nombre: 'Dips'),
          SubcategoryItem(id: '01530', nombre: 'Grasas refrigeradas'),
          SubcategoryItem(id: '01531', nombre: 'Huevos'),
          SubcategoryItem(id: '01529', nombre: 'Leche pasteurizada'),
          SubcategoryItem(id: '01532', nombre: 'Otros lácteos'),
          SubcategoryItem(id: '01528', nombre: 'Queso'),
        ],
      ),
      CategoryGroup(
        id: '016',
        nombre: 'Yogurts',
        subcategorias: [
          SubcategoryItem(id: '01637', nombre: 'Postres'),
          SubcategoryItem(id: '01634', nombre: 'Yogurts'),
          SubcategoryItem(id: '01636', nombre: 'Yogurts griegos'),
        ],
      ),
    ],
  ),
  const MainCategory(
    id: '03',
    nombre: 'Abarrotes',
    tituloCompleto: 'Abarrotes',
    icon: Icons.kitchen_rounded,
    grupos: [
      CategoryGroup(
        id: '031',
        nombre: 'Aceites y grasas',
        subcategorias: [
          SubcategoryItem(id: '03162', nombre: 'Aceite de canola'),
          SubcategoryItem(id: '03166', nombre: 'Aceite de girasol'),
          SubcategoryItem(id: '03165', nombre: 'Aceite de maíz'),
          SubcategoryItem(id: '03161', nombre: 'Aceite de oliva'),
          SubcategoryItem(id: '03164', nombre: 'Aceites de palma y soya'),
          SubcategoryItem(id: '03163', nombre: 'Aceites mezclados'),
          SubcategoryItem(id: '03167', nombre: 'Manteca'),
          SubcategoryItem(id: '03168', nombre: 'Margarinas'),
          SubcategoryItem(id: '03169', nombre: 'Otros aceites y grasas'),
        ],
      ),
      CategoryGroup(
        id: '0311',
        nombre: 'Confitería',
        subcategorias: [
          SubcategoryItem(id: '0311128', nombre: 'Chicles'),
          SubcategoryItem(id: '0311127', nombre: 'Chocolate'),
          SubcategoryItem(id: '0311129', nombre: 'Dulces'),
          SubcategoryItem(id: '0311126', nombre: 'Marshmallow'),
        ],
      ),
      CategoryGroup(
        id: '033',
        nombre: 'Granos básicos',
        subcategorias: [
          SubcategoryItem(id: '03376', nombre: 'Arroces'),
          SubcategoryItem(id: '03377', nombre: 'Frijoles'),
          SubcategoryItem(id: '03379', nombre: 'Otros granos'),
          SubcategoryItem(id: '03378', nombre: 'Sal'),
        ],
      ),
      CategoryGroup(
        id: '0314',
        nombre: 'Mieles, untables y pancakes',
        subcategorias: [
          SubcategoryItem(id: '0314137', nombre: 'Mieles y siropes'),
          SubcategoryItem(id: '0314139', nombre: 'Pancake'),
          SubcategoryItem(id: '0314138', nombre: 'Untables'),
        ],
      ),
      CategoryGroup(
        id: '034',
        nombre: 'Pastas alimenticias',
        subcategorias: [
          SubcategoryItem(id: '03484', nombre: 'Chao mein'),
          SubcategoryItem(id: '03481', nombre: 'Lasagna y canelloni'),
          SubcategoryItem(id: '03482', nombre: 'Pasta corta'),
          SubcategoryItem(id: '03480', nombre: 'Pasta larga'),
          SubcategoryItem(id: '03486', nombre: 'Pastas preparadas'),
          SubcategoryItem(id: '03485', nombre: 'Queso para pastas'),
          SubcategoryItem(id: '03483', nombre: 'Raviolis y tortellini'),
        ],
      ),
      CategoryGroup(
        id: '0316',
        nombre: 'Sopas y cremas',
        subcategorias: [
          SubcategoryItem(id: '0316145', nombre: 'Cremas'),
          SubcategoryItem(id: '0316143', nombre: 'Pures'),
          SubcategoryItem(id: '0316144', nombre: 'Sopas'),
        ],
      ),
      CategoryGroup(
        id: '035',
        nombre: 'Azúcar y productos para hornear',
        subcategorias: [
          SubcategoryItem(id: '03587', nombre: 'Azúcar y sustitutos'),
          SubcategoryItem(id: '03589', nombre: 'Bases para hornear'),
          SubcategoryItem(id: '03591', nombre: 'Lácteos para cocina'),
          SubcategoryItem(id: '03588', nombre: 'Postres instantáneos'),
          SubcategoryItem(id: '03590', nombre: 'Toppings y accesorios'),
        ],
      ),
      CategoryGroup(
        id: '0313',
        nombre: 'Cereales, barras y granola',
        subcategorias: [
          SubcategoryItem(id: '0313134', nombre: 'Avenas'),
          SubcategoryItem(id: '0313136', nombre: 'Barras de cereal'),
          SubcategoryItem(id: '0313133', nombre: 'Cereales'),
          SubcategoryItem(id: '0313135', nombre: 'Granola y afrechos'),
        ],
      ),
      CategoryGroup(
        id: '0312',
        nombre: 'Galletas',
        subcategorias: [
          SubcategoryItem(id: '0312131', nombre: 'Galleta dulce'),
          SubcategoryItem(id: '0312130', nombre: 'Galleta salada'),
          SubcategoryItem(id: '0312132', nombre: 'Galleta saludable'),
        ],
      ),
      CategoryGroup(
        id: '032',
        nombre: 'Harinas',
        subcategorias: [
          SubcategoryItem(id: '03273', nombre: 'Almidón'),
          SubcategoryItem(id: '03270', nombre: 'Atoles y maicenas'),
          SubcategoryItem(id: '03275', nombre: 'Harina de arroz'),
          SubcategoryItem(id: '03271', nombre: 'Harina de maíz'),
          SubcategoryItem(id: '03272', nombre: 'Harina de trigo'),
          SubcategoryItem(id: '03274', nombre: 'Harinas preparadas'),
        ],
      ),
      CategoryGroup(
        id: '039',
        nombre: 'Pan y tortillas',
        subcategorias: [
          SubcategoryItem(id: '039112', nombre: 'Bollería'),
          SubcategoryItem(id: '039115', nombre: 'Cakitos'),
          SubcategoryItem(id: '039116', nombre: 'Empanizadores'),
          SubcategoryItem(id: '039110', nombre: 'Pan de caja'),
          SubcategoryItem(id: '039114', nombre: 'Pan dulce'),
          SubcategoryItem(id: '039113', nombre: 'Pan salado'),
          SubcategoryItem(id: '039111', nombre: 'Tortillas'),
        ],
      ),
      CategoryGroup(
        id: '0317',
        nombre: 'Salsas, aderezos y vinagres',
        subcategorias: [
          SubcategoryItem(id: '0317149', nombre: 'Productos para ensaladas'),
          SubcategoryItem(id: '0317147', nombre: 'Salsas'),
          SubcategoryItem(id: '0317148', nombre: 'Vinagres'),
          SubcategoryItem(id: '0317146', nombre: 'Viscosos'),
        ],
      ),
      CategoryGroup(
        id: '0310',
        nombre: 'Boquitas',
        subcategorias: [
          SubcategoryItem(id: '0310122', nombre: 'Dips para boquitas'),
          SubcategoryItem(id: '0310123', nombre: 'Extruidos'),
          SubcategoryItem(id: '0310125', nombre: 'Otras boquitas'),
          SubcategoryItem(id: '0310121', nombre: 'Palomitas de maíz'),
          SubcategoryItem(id: '0310117', nombre: 'Papitas'),
          SubcategoryItem(id: '0310120', nombre: 'Plátanos'),
          SubcategoryItem(id: '0310124', nombre: 'Semillas'),
          SubcategoryItem(id: '0310118', nombre: 'Tortillitas'),
          SubcategoryItem(id: '0310119', nombre: 'Yucas'),
        ],
      ),
      CategoryGroup(
        id: '036',
        nombre: 'Enlatados y conservas',
        subcategorias: [
          SubcategoryItem(id: '03694', nombre: 'Aceitunas y encurtidos'),
          SubcategoryItem(id: '03695', nombre: 'Atún'),
          SubcategoryItem(id: '03698', nombre: 'Carne de pescado'),
          SubcategoryItem(id: '03697', nombre: 'Carnes en conserva'),
          SubcategoryItem(id: '03699', nombre: 'Crustáceos'),
          SubcategoryItem(id: '03693', nombre: 'Frutas en conserva'),
          SubcategoryItem(id: '036100', nombre: 'Moluscos'),
          SubcategoryItem(id: '03696', nombre: 'Sardinas'),
          SubcategoryItem(id: '03692', nombre: 'Vegetales en conserva'),
        ],
      ),
      CategoryGroup(
        id: '037',
        nombre: 'Leche y bebidas vegetales',
        subcategorias: [
          SubcategoryItem(id: '037104', nombre: 'Bebida nutricional'),
          SubcategoryItem(id: '037103', nombre: 'Bebidas vegetales'),
          SubcategoryItem(id: '037106', nombre: 'Culinarios'),
          SubcategoryItem(id: '037101', nombre: 'Leche en polvo'),
          SubcategoryItem(id: '037102', nombre: 'Leche liquida'),
          SubcategoryItem(id: '037105', nombre: 'Modificadores lácteos'),
          SubcategoryItem(id: '037107', nombre: 'Otras leches y bebidas vegetales'),
        ],
      ),
      CategoryGroup(
        id: '0318',
        nombre: 'Salsas de tomate',
        subcategorias: [
          SubcategoryItem(id: '0318152', nombre: 'Kétchup'),
          SubcategoryItem(id: '0318151', nombre: 'Salsas para pasta'),
          SubcategoryItem(id: '0318150', nombre: 'Tomatinas'),
        ],
      ),
      CategoryGroup(
        id: '0315',
        nombre: 'Sazonadores y especias',
        subcategorias: [
          SubcategoryItem(id: '0315142', nombre: 'Caldos'),
          SubcategoryItem(id: '0315141', nombre: 'Consomés'),
          SubcategoryItem(id: '0315140', nombre: 'Especias'),
        ],
      ),
    ],
  ),
  const MainCategory(
    id: '05',
    nombre: 'Bebidas',
    tituloCompleto: 'Bebidas',
    icon: Icons.local_drink_rounded,
    grupos: [
      CategoryGroup(
        id: '051',
        nombre: 'Agua',
        subcategorias: [
          SubcategoryItem(id: '051174', nombre: 'Agua'),
        ],
      ),
      CategoryGroup(
        id: '052',
        nombre: 'Energizante y bebidas deportivas',
        subcategorias: [
          SubcategoryItem(id: '052176', nombre: 'Bebidas deportivas'),
          SubcategoryItem(id: '052175', nombre: 'Energizantes'),
        ],
      ),
      CategoryGroup(
        id: '053',
        nombre: 'Sodas',
        subcategorias: [
          SubcategoryItem(id: '053177', nombre: 'Colas'),
          SubcategoryItem(id: '053178', nombre: 'Sabores'),
        ],
      ),
      CategoryGroup(
        id: '054',
        nombre: 'Jugos y néctares',
        subcategorias: [
          SubcategoryItem(id: '054179', nombre: 'Jugos preparados'),
          SubcategoryItem(id: '054179', nombre: 'Jugos y néctares'),
        ],
      ),
      CategoryGroup(
        id: '055',
        nombre: 'Refrescos y otros',
        subcategorias: [
          SubcategoryItem(id: '055182', nombre: 'Bebidas de soya / avena'),
          SubcategoryItem(id: '055', nombre: 'Bebidas en polvo y concentrados'),
          SubcategoryItem(id: '055181', nombre: 'Refrescos'),
        ],
      ),
      CategoryGroup(
        id: '056',
        nombre: 'Bebidas de aloe',
        subcategorias: [
          SubcategoryItem(id: '056184', nombre: 'Bebidas de aloe'),
        ],
      ),
      CategoryGroup(
        id: '057',
        nombre: 'Bebidas de te',
        subcategorias: [
          SubcategoryItem(id: '057185', nombre: 'Bebidas a base de te'),
          SubcategoryItem(id: '057', nombre: 'Bebidas en polvo y concentrados'),
          SubcategoryItem(id: '057', nombre: 'Te e infusiones'),
        ],
      ),
      CategoryGroup(
        id: '058',
        nombre: 'Café',
        subcategorias: [
          SubcategoryItem(id: '058186', nombre: 'Bebidas de café'),
          SubcategoryItem(id: '058187', nombre: 'Café soluble'),
          SubcategoryItem(id: '058188', nombre: 'Café tostado'),
          SubcategoryItem(id: '058190', nombre: 'Cremadores'),
        ],
      ),
      CategoryGroup(
        id: '059',
        nombre: 'Bebidas calientes',
        subcategorias: [
          SubcategoryItem(id: '059191', nombre: 'Otras bebidas calientes'),
        ],
      ),
      CategoryGroup(
        id: '0510',
        nombre: 'Bebidas refrigeradas',
        subcategorias: [
          SubcategoryItem(id: '0510192', nombre: 'Bebidas refrigeradas'),
        ],
      ),
    ],
  ),
  const MainCategory(
    id: '02',
    nombre: 'Productos\ncongelados',
    tituloCompleto: 'Productos congelados',
    icon: Icons.ac_unit_rounded,
    grupos: [
      CategoryGroup(
        id: '021',
        nombre: 'Productos congelados',
        subcategorias: [
          SubcategoryItem(id: '02149', nombre: 'Carnes congeladas'),
          SubcategoryItem(id: '02155', nombre: 'Comida típica congelada'),
          SubcategoryItem(id: '02156', nombre: 'Comidas congeladas'),
          SubcategoryItem(id: '02157', nombre: 'Frutas congeladas'),
          SubcategoryItem(id: '02152', nombre: 'Hielo'),
          SubcategoryItem(id: '02160', nombre: 'Otros productos congelados'),
          SubcategoryItem(id: '02158', nombre: 'Pan congelado'),
          SubcategoryItem(id: '02153', nombre: 'Papas congeladas'),
          SubcategoryItem(id: '02159', nombre: 'Pizzas congeladas'),
          SubcategoryItem(id: '02151', nombre: 'Postres congelados'),
          SubcategoryItem(id: '02150', nombre: 'Snacks congelados'),
          SubcategoryItem(id: '02154', nombre: 'Vegetales congelados'),
        ],
      ),
    ],
  ),
  const MainCategory(
    id: '08',
    nombre: 'Cuidado\npersonal',
    tituloCompleto: 'Cuidado personal',
    icon: Icons.spa_rounded,
    grupos: [
      CategoryGroup(
        id: '084',
        nombre: 'Afeitado',
        subcategorias: [
          SubcategoryItem(id: '084247', nombre: 'Productos para afeitar'),
        ],
      ),
      CategoryGroup(
        id: '086',
        nombre: 'Cuidado bucal',
        subcategorias: [
          SubcategoryItem(id: '086265', nombre: 'Cepillos dentales'),
          SubcategoryItem(id: '086264', nombre: 'Cremas dentales'),
          SubcategoryItem(id: '086266', nombre: 'Enjuagues'),
          SubcategoryItem(id: '086267', nombre: 'Otros productos de cuidado bucal'),
        ],
      ),
      CategoryGroup(
        id: '088',
        nombre: 'Cuidado femenino',
        subcategorias: [
          SubcategoryItem(id: '088275', nombre: 'Higiene femenina'),
          SubcategoryItem(id: '088274', nombre: 'Protectores diarios'),
          SubcategoryItem(id: '088273', nombre: 'Tampones'),
          SubcategoryItem(id: '088272', nombre: 'Toallas femeninas'),
        ],
      ),
      CategoryGroup(
        id: '081',
        nombre: 'Jabones corporales',
        subcategorias: [
          SubcategoryItem(id: '081239', nombre: 'Alcohol gel'),
          SubcategoryItem(id: '081237', nombre: 'Gel para baño'),
          SubcategoryItem(id: '081235', nombre: 'Jabones de tocador'),
          SubcategoryItem(id: '081236', nombre: 'Jabones líquidos'),
          SubcategoryItem(id: '081238', nombre: 'Otros accesorios corporales'),
        ],
      ),
      CategoryGroup(
        id: '0811',
        nombre: 'Salud y medicamentos',
        subcategorias: [
          SubcategoryItem(id: '0811285', nombre: 'Analgésicos'),
          SubcategoryItem(id: '0811286', nombre: 'Antiácidos'),
          SubcategoryItem(id: '0811288', nombre: 'Antialérgico'),
          SubcategoryItem(id: '0811289', nombre: 'Anticonceptivos'),
          SubcategoryItem(id: '0811287', nombre: 'Antigripal'),
          SubcategoryItem(id: '0811291', nombre: 'Dermatológico'),
          SubcategoryItem(id: '0811292', nombre: 'Gastrointestinal'),
          SubcategoryItem(id: '0811290', nombre: 'Otros medicamentos y salud'),
          SubcategoryItem(id: '0811283', nombre: 'Primeros auxilios'),
          SubcategoryItem(id: '0811293', nombre: 'Suero'),
          SubcategoryItem(id: '0811294', nombre: 'Tos y garganta'),
          SubcategoryItem(id: '0811295', nombre: 'Ungüentos'),
          SubcategoryItem(id: '0811284', nombre: 'Vitaminas'),
        ],
      ),
      CategoryGroup(
        id: '0810',
        nombre: 'Cosméticos y maquillaje',
        subcategorias: [
          SubcategoryItem(id: '0810281', nombre: 'Accesorios de belleza'),
          SubcategoryItem(id: '0810280', nombre: 'Mercería'),
          SubcategoryItem(id: '0810282', nombre: 'Productos de belleza'),
        ],
      ),
      CategoryGroup(
        id: '085',
        nombre: 'Cuidado de la piel',
        subcategorias: [
          SubcategoryItem(id: '085249', nombre: 'Bronceadores y protectores'),
          SubcategoryItem(id: '085252', nombre: 'Cremas anticelulitis'),
          SubcategoryItem(id: '085248', nombre: 'Cremas humectantes'),
          SubcategoryItem(id: '085260', nombre: 'Cremas para ojos'),
          SubcategoryItem(id: '085253', nombre: 'Cremas tratamiento maternal'),
          SubcategoryItem(id: '085251', nombre: 'Cremas y limpiadores faciales'),
          SubcategoryItem(id: '085258', nombre: 'Desmaquillador de ojos'),
          SubcategoryItem(id: '085261', nombre: 'Exfoliantes'),
          SubcategoryItem(id: '085256', nombre: 'Jabones faciales'),
          SubcategoryItem(id: '085257', nombre: 'Mascarillas faciales'),
          SubcategoryItem(id: '085263', nombre: 'Otros productos de cuidado de la piel'),
          SubcategoryItem(id: '085250', nombre: 'Splash'),
          SubcategoryItem(id: '085254', nombre: 'Talcos y talqueras'),
          SubcategoryItem(id: '085259', nombre: 'Tónicos faciales'),
          SubcategoryItem(id: '085262', nombre: 'Tratamientos faciales especializados'),
          SubcategoryItem(id: '085255', nombre: 'Tratamientos para pies'),
        ],
      ),
      CategoryGroup(
        id: '089',
        nombre: 'Cuidado adulto mayor',
        subcategorias: [
          SubcategoryItem(id: '089277', nombre: 'Cuidado adulto mayor'),
          SubcategoryItem(id: '089278', nombre: 'Pañales para adulto'),
          SubcategoryItem(id: '089276', nombre: 'Protectores para incontinencia'),
          SubcategoryItem(id: '089279', nombre: 'Ropa interior'),
        ],
      ),
      CategoryGroup(
        id: '082',
        nombre: 'Cuidado del cabello',
        subcategorias: [
          SubcategoryItem(id: '082244', nombre: 'Accesorios para el cabello'),
          SubcategoryItem(id: '082241', nombre: 'Acondicionador'),
          SubcategoryItem(id: '082240', nombre: 'Shampoo'),
          SubcategoryItem(id: '082242', nombre: 'Terceros pasos'),
          SubcategoryItem(id: '082243', nombre: 'Tintes para el cabello'),
        ],
      ),
      CategoryGroup(
        id: '083',
        nombre: 'Desodorantes',
        subcategorias: [
          SubcategoryItem(id: '083246', nombre: 'Desodorantes femeninos'),
          SubcategoryItem(id: '083245', nombre: 'Desodorantes masculinos'),
        ],
      ),
      CategoryGroup(
        id: '087',
        nombre: 'Papel higiénico',
        subcategorias: [
          SubcategoryItem(id: '087270', nombre: 'Papel alto rendimiento'),
          SubcategoryItem(id: '087271', nombre: 'Papel economía'),
          SubcategoryItem(id: '087268', nombre: 'Papel máxima suavidad'),
          SubcategoryItem(id: '087269', nombre: 'Papel suavidad rendimiento'),
        ],
      ),
    ],
  ),
  const MainCategory(
    id: '07',
    nombre: 'Cuidado del\nhogar',
    tituloCompleto: 'Cuidado del hogar',
    icon: Icons.cleaning_services_rounded,
    grupos: [
      CategoryGroup(
        id: '075',
        nombre: 'Ambientales',
        subcategorias: [
          SubcategoryItem(id: '075224', nombre: 'Ambientales'),
        ],
      ),
      CategoryGroup(
        id: '073',
        nombre: 'Desechables y papeles para cocina',
        subcategorias: [
          SubcategoryItem(id: '073216', nombre: 'Desechables'),
          SubcategoryItem(id: '073219', nombre: 'Papel aluminio'),
          SubcategoryItem(id: '073220', nombre: 'Papel encerado'),
          SubcategoryItem(id: '073221', nombre: 'Papel plástico'),
          SubcategoryItem(id: '073218', nombre: 'Papel toalla'),
          SubcategoryItem(id: '073217', nombre: 'Servilletas'),
        ],
      ),
      CategoryGroup(
        id: '072',
        nombre: 'Lavaplatos',
        subcategorias: [
          SubcategoryItem(id: '072214', nombre: 'Lavaplatos'),
          SubcategoryItem(id: '072215', nombre: 'Limpieza de trastos y cocina'),
        ],
      ),
      CategoryGroup(
        id: '074',
        nombre: 'Bolsas plásticas',
        subcategorias: [
          SubcategoryItem(id: '074222', nombre: 'Bolsas biodegradables'),
          SubcategoryItem(id: '074223', nombre: 'Bolsas no degradables'),
        ],
      ),
      CategoryGroup(
        id: '071',
        nombre: 'Desinfección y limpieza',
        subcategorias: [
          SubcategoryItem(id: '071213', nombre: 'Accesorios de limpieza'),
          SubcategoryItem(id: '071209', nombre: 'Desinfección'),
          SubcategoryItem(id: '071211', nombre: 'Limpiadores de madera y metal'),
          SubcategoryItem(id: '071212', nombre: 'Limpiadores para cocina'),
          SubcategoryItem(id: '071210', nombre: 'Productos de limpieza para baño'),
        ],
      ),
      CategoryGroup(
        id: '076',
        nombre: 'Control de plagas',
        subcategorias: [
          SubcategoryItem(id: '076227', nombre: 'Accesorios para plagas'),
          SubcategoryItem(id: '076225', nombre: 'Insecticidas'),
          SubcategoryItem(id: '076226', nombre: 'Repelentes'),
        ],
      ),
      CategoryGroup(
        id: '077',
        nombre: 'Lavandería',
        subcategorias: [
          SubcategoryItem(id: '077233', nombre: 'Almidones'),
          SubcategoryItem(id: '077228', nombre: 'Detergentes'),
          SubcategoryItem(id: '077229', nombre: 'Jabones para lavar'),
          SubcategoryItem(id: '077231', nombre: 'Lejías y cloros'),
          SubcategoryItem(id: '077234', nombre: 'Otros productos de lavandería'),
          SubcategoryItem(id: '077232', nombre: 'Removedor de manchas'),
          SubcategoryItem(id: '077230', nombre: 'Suavizantes'),
        ],
      ),
    ],
  ),
  const MainCategory(
    id: '09',
    nombre: 'Cuidado del\nbebé',
    tituloCompleto: 'Cuidado del bebé',
    icon: Icons.child_care_rounded,
    grupos: [
      CategoryGroup(
        id: '095',
        nombre: 'Colados, cereales y bebidas infantiles',
        subcategorias: [
          SubcategoryItem(id: '095305', nombre: 'Agua purificada para bebé'),
          SubcategoryItem(id: '095303', nombre: 'Cereales infantiles'),
          SubcategoryItem(id: '095302', nombre: 'Colados infantiles'),
          SubcategoryItem(id: '095304', nombre: 'Jugos infantiles'),
          SubcategoryItem(id: '095306', nombre: 'Snacks infantiles'),
        ],
      ),
      CategoryGroup(
        id: '091',
        nombre: 'Cosméticos y accesorios infantiles',
        subcategorias: [
          SubcategoryItem(id: '091296', nombre: 'Accesorios infantiles'),
          SubcategoryItem(id: '091297', nombre: 'Cosméticos infantiles'),
        ],
      ),
      CategoryGroup(
        id: '093',
        nombre: 'Toallas húmedas',
        subcategorias: [
          SubcategoryItem(id: '093300', nombre: 'Toallas húmedas'),
        ],
      ),
      CategoryGroup(
        id: '094',
        nombre: 'Formulas infantiles',
        subcategorias: [
          SubcategoryItem(id: '094301', nombre: 'Formulas infantiles'),
        ],
      ),
      CategoryGroup(
        id: '092',
        nombre: 'Pañales desechables',
        subcategorias: [
          SubcategoryItem(id: '092299', nombre: 'Calzón de entrenamiento'),
          SubcategoryItem(id: '092298', nombre: 'Pañales desechables de bebe'),
        ],
      ),
    ],
  ),
  const MainCategory(
    id: '06',
    nombre: 'Cuidado\nmascotas',
    tituloCompleto: 'Cuidado mascotas',
    icon: Icons.pets_rounded,
    grupos: [
      CategoryGroup(
        id: '063',
        nombre: 'Accesorios mascotas',
        subcategorias: [
          SubcategoryItem(id: '063205', nombre: 'Bozales'),
          SubcategoryItem(id: '063206', nombre: 'Cadena'),
          SubcategoryItem(id: '063204', nombre: 'Cepillos'),
          SubcategoryItem(id: '063202', nombre: 'Collares'),
          SubcategoryItem(id: '063203', nombre: 'Juguetes de mascota'),
          SubcategoryItem(id: '063208', nombre: 'Otros accesorios mascotas'),
          SubcategoryItem(id: '063207', nombre: 'Pechera'),
        ],
      ),
      CategoryGroup(
        id: '061',
        nombre: 'Comida mascotas',
        subcategorias: [
          SubcategoryItem(id: '061195', nombre: 'Alimento otras mascotas'),
          SubcategoryItem(id: '061194', nombre: 'Alimento para gatos'),
          SubcategoryItem(id: '061193', nombre: 'Alimento para perros'),
        ],
      ),
      CategoryGroup(
        id: '062',
        nombre: 'Higiene mascotas',
        subcategorias: [
          SubcategoryItem(id: '062198', nombre: 'Desodorizante para mascota'),
          SubcategoryItem(id: '062197', nombre: 'Jabón para mascota'),
          SubcategoryItem(id: '062199', nombre: 'Otros productos para mascotas'),
          SubcategoryItem(id: '062200', nombre: 'Rinse de mascota'),
          SubcategoryItem(id: '062196', nombre: 'Shampoo de mascota'),
          SubcategoryItem(id: '062201', nombre: 'Talcos para mascota'),
        ],
      ),
    ],
  ),
  const MainCategory(
    id: '10',
    nombre: 'Mercancías\ngenerales',
    tituloCompleto: 'Mercancias generales',
    icon: Icons.storefront_rounded,
    grupos: [
      CategoryGroup(
        id: '101',
        nombre: 'Mercancías generales',
        subcategorias: [
          SubcategoryItem(id: '101311', nombre: 'Artículos del hogar'),
          SubcategoryItem(id: '101307', nombre: 'Ferretería'),
          SubcategoryItem(id: '101309', nombre: 'Juguetes'),
          SubcategoryItem(id: '101312', nombre: 'Navideño'),
          SubcategoryItem(id: '101310', nombre: 'Papelería y útiles'),
          SubcategoryItem(id: '101308', nombre: 'Ropa'),
        ],
      ),
    ],
  ),
  const MainCategory(
    id: '04',
    nombre: 'Cervezas, vinos\ny licores',
    tituloCompleto: 'Cervezas, vinos y licores',
    icon: Icons.sports_bar_rounded,
    grupos: [
      CategoryGroup(
        id: '045',
        nombre: 'Bebidas preparadas',
        subcategorias: [
          SubcategoryItem(id: '045172', nombre: 'Hard Seltzer'),
          SubcategoryItem(id: '045173', nombre: 'RTDS'),
        ],
      ),
      CategoryGroup(
        id: '043',
        nombre: 'Sidras y sangrías',
        subcategorias: [
          SubcategoryItem(id: '043163', nombre: 'Coolers'),
          SubcategoryItem(id: '043164', nombre: 'Sangrías'),
          SubcategoryItem(id: '043162', nombre: 'Sidras'),
        ],
      ),
      CategoryGroup(
        id: '041',
        nombre: 'Cervezas',
        subcategorias: [
          SubcategoryItem(id: '041155', nombre: 'Cerveza artesanal'),
          SubcategoryItem(id: '041153', nombre: 'Cerveza premium'),
          SubcategoryItem(id: '041154', nombre: 'Cerveza regular'),
          SubcategoryItem(id: '041156', nombre: 'Root beer'),
        ],
      ),
      CategoryGroup(
        id: '042',
        nombre: 'Vinos y espumantes',
        subcategorias: [
          SubcategoryItem(id: '042160', nombre: 'Cavas'),
          SubcategoryItem(id: '042161', nombre: 'Champagne'),
          SubcategoryItem(id: '042157', nombre: 'Vinos blancos'),
          SubcategoryItem(id: '042158', nombre: 'Vinos rosados'),
          SubcategoryItem(id: '042159', nombre: 'Vinos tintos'),
        ],
      ),
      CategoryGroup(
        id: '044',
        nombre: 'Licores',
        subcategorias: [
          SubcategoryItem(id: '044171', nombre: 'Agua ardiente'),
          SubcategoryItem(id: '044169', nombre: 'Aperitivos y digestivos'),
          SubcategoryItem(id: '044170', nombre: 'Mezclas'),
          SubcategoryItem(id: '044166', nombre: 'Rones'),
          SubcategoryItem(id: '044168', nombre: 'Tequilas'),
          SubcategoryItem(id: '044165', nombre: 'Vodkas'),
          SubcategoryItem(id: '044167', nombre: 'Whiskys'),
        ],
      ),
    ],
  ),
  const MainCategory(
    id: '11',
    nombre: 'Tecnología',
    tituloCompleto: 'Tecnología',
    icon: Icons.devices_rounded,
    grupos: [
      CategoryGroup(
        id: '111',
        nombre: 'Tecnología',
        subcategorias: [
          SubcategoryItem(id: '111314', nombre: 'Accesorios tecnológicos'),
          SubcategoryItem(id: '111313', nombre: 'Telefonía'),
        ],
      ),
    ],
  ),
  const MainCategory(
    id: '12',
    nombre: 'Giftcards',
    tituloCompleto: 'Giftcards',
    icon: Icons.card_giftcard_rounded,
    grupos: [
      CategoryGroup(
        id: '12',
        nombre: 'Giftcards',
        subcategorias: [
          SubcategoryItem(id: '12', nombre: 'Tarjetas de regalo'),
        ],
      ),
    ],
  ),
];
