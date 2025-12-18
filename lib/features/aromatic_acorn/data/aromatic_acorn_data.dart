import '../model/aromatic_acorn_stage.dart';

class AromaticAcornData {
  static const List<AromaticAcornStage> stages = [
    AromaticAcornStage(
      id: 'entrance',
      title: 'Aromatic Acorn Entrance Exam',
      requirements: [
        'Rating must be at least 2,000',
        'Complete the judging within 3 days from participation',
        'Must unlock River God Pond',
        'Must unlock Slab Path',
      ],
      tasks: [
        'Earn more than 2,500,000 Cod',
        'Serve 150 Promo Customers from Village (Radio)',
        'Serve 100 Promo Customers from Town (TV)',
        'Sell 70 Taiyakis',
      ],
      rewards: [
        'Diamonds +10',
        'Cod +500,000',
      ],
    ),

    AromaticAcornStage(
      id: '1',
      title: 'Aromatic Acorn 1-Star Judging',
      requirements: [
        'Rating must be at least 5,000',
        'Complete Aromatic Acorn Entrance Exam',
        'Complete the judging within 7 days from participation',
        'Must unlock Moss Path',
        'Learn recipe: Rice Pudding',
        'Learn recipe: Chicken Burger',
      ],
      tasks: [
        'Earn more than 1,500,000 Cod',
        'Serve 500 Promo Customers from Village (Radio)',
        'Sell 150 Taiyakis',
        'Gather customers 15 times',
        'Play Game Machine 5 times',
      ],
      rewards: [
        'Aromatic Acorn 1-Star Certificate (Courtyard wall)',
        'Diamonds +20',
        'Cod +1,000,000',
      ],
    ),

    AromaticAcornStage(
      id: '2',
      title: 'Aromatic Acorn 2-Star Judging',
      requirements: [
        'Rating must be at least 15,000',
        'Complete Aromatic Acorn 1-Star Judging',
        'Complete the judging within 18 days from participation',
        'Unlock: Hanging Honors',
        'Unlock: Message Bottle',
        'Learn recipe: Strawberry Shaved Ice',
      ],
      tasks: [
        'Serve 800 Promo Customers from Village (Radio)',
        'Have 500 flower viewing customers',
        'Plant 60 Daisy (any level)',
        'Plant 30 Bluebell (any level)',
        'Make 80 wishes',
        'Send Hedwig out 15 times',
      ],
      rewards: [
        'Aromatic Acorn 2-Star Certificate (Courtyard wall)',
        'Diamonds +30',
        'Plates +800',
      ],
    ),

    AromaticAcornStage(
      id: '3',
      title: 'Aromatic Acorn 3-Star Judging',
      requirements: [
        'Rating must be at least 30,000',
        'Complete Aromatic Acorn 2-Star Judging',
        'Complete the judging within 25 days from participation',
        'Unlock: Flag of Spoils',
        'Unlock: Fruity Counter',
        'Learn: Buckwheat Noodles',
        'Learn: Snail Noodles',
        'Learn: Conveyor Miso Soup',
      ],
      tasks: [
        'Earn 130,000,000 Cod',
        'Attract 120 Booth Owners',
        'Catch 8 Sharks',
        'Catch 25 Flounders',
        'Tap Promo 6,400 times',
      ],
      rewards: [
        'Aromatic Acorn 3-Star Certificate (Courtyard wall)',
        'Diamonds +30',
        'Golden Spatula',
      ],
    ),

    AromaticAcornStage(
      id: '4',
      title: 'Aromatic Acorn 4-Star Judging',
      requirements: [
        'Rating must be at least 50,000',
        'Complete Aromatic Acorn 3-Star Judging',
        'Complete the judging within 35 days from participation',
        'Unlock: Beach Impression',
        'Unlock: Handcart Sweets',
        'Learn: Black Sesame Paste',
        'Learn: Mapo Tofu',
        'Learn: Pearl Milk Tea',
        'Learn buffet: Conveyor Custard',
        'Learn buffet: Conveyor Potstickers',
      ],
      tasks: [
        'Serve 1,500 Promo Customers from Town (TV)',
        'Catch 40 Clownfish',
        'Catch 35 Squid',
        'Deliver 60 takeouts',
        'Sweep up trash 40 times',
      ],
      rewards: [
        'Aromatic Acorn 4-Star Certificate (Courtyard wall)',
        'Diamonds +50',
        'Kitty Dish',
      ],
    ),

    AromaticAcornStage(
      id: '5',
      title: 'Aromatic Acorn 5-Star Judging',
      requirements: [
        'Rating must be at least 100,000',
        'Complete Aromatic Acorn 4-Star Judging',
        'Complete the judging within 45 days from participation',
        'Unlock: Seashell Counter',
        'Unlock: Octopus Coffee',
        'Unlock: Yacht Counter',
        'Learn: Eight Treasure Rice Pudding',
        'Learn: Strawberry Pudding',
        'Learn: Mugwort Dumpling',
        'Learn buffet: Tuna Sushi',
        'Learn buffet: Fried Chicken Skin',
      ],
      tasks: [
        'Serve 2,000 Promo Customers from Town (TV)',
        'Gamble with Card-Playing Mouse 25 times',
        'Sweep up trash 60 times',
        'Have 1,500 flower viewing customers',
        'Earn 650,000,000 Cod',
        'Sell 50 Seaweed Rice Ball',
      ],
      rewards: [
        'Aromatic Acorn 5-Star Certificate (Courtyard wall)',
        'Diamonds +50',
        'Rising Star',
      ],
    ),

    AromaticAcornStage(
      id: '6',
      title: 'Aromatic Acorn 6-Star Judging',
      requirements: [
        'Rating must be at least 200,000',
        'Complete Aromatic Acorn 5-Star Judging',
        'Complete the judging within 55 days from participation',
        'Unlock: Banana Peel Capsule Machine',
        'Learn: Crispy Fried Meat',
        'Learn buffet: Japanese Ramen',
        'Learn buffet: Meat Floss Sushi',
      ],
      tasks: [
        'Serve 2,800 Promo Customers from City (Cellphone)',
        'Have 1,500 flower viewing customers',
        'Send Hedwig out 40 times',
        'Attract 15 different types of Booth Owners',
        'Sweep up trash 80 times',
        'Catch 18 Sharks',
        'Play the Game Machine 40 times',
        'Plant 50 Bluebell (any level)',
        'Make 110 wishes',
      ],
      rewards: [
        'Aromatic Acorn 6-Star Certificate (Courtyard wall)',
        'Diamonds +80',
        'Glorious Barrette',
      ],
    ),

    AromaticAcornStage(
      id: '7',
      title: 'Aromatic Acorn 7-Star Judging',
      requirements: [
        'Rating must be at least 350,000',
        'Complete Aromatic Acorn 6-Star Judging',
        'Complete the judging within 65 days from participation',
      ],
      tasks: [
        'Serve 4,800 Promo Customers from City (Cellphone)',
        'Earn 900,000,000 Cod',
        'Sell 120 Taiyakis',
        'Gamble with Card-Playing Mouse 35 times',
        'Tap Promo 15,000 times',
        'Make 800 wishes',
        'Plant 80 Rose (any level)',
        'Deliver 150 takeouts',
        'Attract 25 different types of Booth Owners',
        'Gather customers 150 times',
        'Sweep up trash 80 times',
        'Send Hedwig out 50 times',
        'Have 2,200 flower viewing customers',
        'Play the Game Machine 45 times',
      ],
      rewards: [
        'Aromatic Acorn 7-Star Certificate (Courtyard wall)',
        'Diamonds +100',
        'Mew-chelin Recipes',
      ],
    ),
  ];
}
