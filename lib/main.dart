import 'package:flutter/material.dart';

/// This modified version of the Animal Restaurant Progress Tracker turns the
/// original counter app skeleton into a simple encyclopedia‑style navigator.
/// It organizes information from the Animal Restaurant wiki into three high‑level
/// sections: Customers, Mementos and Letters.  Each section can be expanded
/// and, where appropriate, subdivided into subsections.  Customer subsections
/// include All, Restaurant, Special, Booth Owner and Performer.  Within each
/// customer subsection is a list of customer names pulled from the wiki.  For
/// Mementos and Letters we expose the counts and categories described in the
/// wiki (e.g., hidden and poster mementos, individual versus series letters)【902878600203546†L0-L8】【66695452104404†L1-L5】.

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Animal Restaurant Progress Tracker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 255, 217, 0),
        ),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Animal Restaurant Progress Tracker'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  /// Names for regular (restaurant) customers.  These names were gathered
  /// manually from the Animal Restaurant wiki.  Only a subset of the full
  /// customer roster is included here; you can extend these lists as needed.
  final List<String> regularCustomers = [
    'White Bunny',
    'Brown Bunny',
    'Deer',
    'Mouse',
    'Striped Yellow Jackal',
    'Badger',
    'Spotted Deer',
    'Artist Badger',
    'Wounded Bear',
    'Hedgehog',
    'Brown Wolf',
    'Striped Jackal',
    'Blueberry Hedgehog',
    'Sheep',
    'Yellow Jackal',
    'Swan',
    'Wolf',
    'Scarred Bear',
    'Granny Wolf',
    'Border Collie',
    'French Bulldog',
    'Bald Sheep',
    'Lop‑Eared Rabbit',
    'Otter',
    'One‑Eyed Papillon',
    'Fox',
    'Raccoon', 
    'Terrier',
    'Field Dog',
    'Shiba',
    'Ostrich',
    'White Shiba',
    'Paper Bagged Ostrich',
    'Berry Hedgehog',
    'Chocolate Lab',
    'Chocolate Border Collie',
    'Boar',
    'Black Shiba',
    'Black Lab',
    'Boston Terrier',
    'Merle Border Collie',
    'Pug',
    'Corgi',
    'Speckled Pig',
    'Husky',
    'Tri‑Colored Corgi',
    'Pig',
    'Old Collie',
    'Fennec Fox',
    'Penguin',
    'White‑Collar Fox',
    'Lynx',
    'Dachshund',
    'Rescue Dog',
    'Sloth',
    'Polar Bear',
    'Slim White Dog',
    'Insta‑Pup',
    'Flamingo',
    'Gnome',
    'Mushroom Sloth',
    'Influencer Flamingo',
    'Tiger',
    'Little Black Dog',
    'White Rabbit',
    'Cheshire Cat',
    'Reporter',
    'Glamourous Lady',
    'Scotch Collie',
    "Programmer’s Dog",
    'Dalmatian',
    'Party Puppy',
    'Green‑Hat Gnome',
    'Cici',
    'Lucky Pig',
    'Shiba Puppy',
    'Alpaca',
    'Little Lion',
    'Abi',
    'Little Fox',
    'Squirrel',
    'Wild Duck',
    'Wood-chuckin\' Beaver',
    'Brown Horse',
    'Yorkie Mom',
    'Yorkie Dad',
    'Pink Piggy',
    'Yorkie Pup',
    'Bean',
    'Dr. Puppy',
    'Moon Rabbit',
    'Capybara',
    'Pangolin Baby',
    'Pangolin Mama',
    'Guru',
    'Red Squirrel',
    'Beaver Engineer',
    'Alaska',
    'Asian Elephant',
    'Hippopotamus',
    'Snow Leopard Pup',
    'Snow Leopard',
    'Adventurer Stoat',
    'Beancurd',
    'Rice Cake',
    'Moose',
    'Aries',
    'Curly',
    'Dorkie',
    'Little Koala',
    'Yannis',
    'Mooey',
    'Mr. Bharal',
    'Chihuahua',
    'Brown Chihuahua',
    'Black & White Chihuahua',
    'Lilith',
    'Rose',
    'Snowy',
    'Sleepwalking Little Lion',
    'Arctic Hare',
    'Mystifying Crane',
    'Nozy',
    'Black Papillon',
    'Eugene the Tree-kangaroo',
    'Bernese Mountain Pup',
    'Miss Rhino',
    'Manager Bear',
    'Golden Retriever',
    'Little Colt',
    'White Mouse',
    'Fancy Rat',
    'Grandpa Spirit Bear',
    'Amber',
    'Dracula',
    'Ahau',
    'Lil\' Duckling',
    'Longevity Fox',
    'Deer of Nine Colors',
    'Dragony',
    'Weeping Croc',
    'Axolotl',
    'Goofy',
    'Honey Badger',
    'Lil\' Giraffe',
    'Quokka',
    'German Shepherd',
    'Annie',
    'Harpy Eagle Wizard',
    'Black Panther',
    'Cong Cong',
    'Er Shu',
    'Cyborg Danny',
    'Fuzzy',
    'Meery',
    'Squiddy',
    'Lemur',
    'Elephant Shrew'
  ];

  /// Names for special customers【625433312635769†L398-L433】.
  final List<String> specialCustomers = [
    'Rich Kid',
    'Ad Salesman',
    'Cod‑Stealing Rabbit',
    'Skunk',
    'Card‑Playing Mouse',
    'Wandering Singer',
    'New Year Mouse',
    'Rascal',
    "Rascal’s Dad",
    "Rascal’s Mom",
    'Christmas Elf',
    'New Year Calf',
    'Cowherd',
    'Weaver Girl',
    'Dani',
    'Halloween Ragdoll',
    'Snowball 2',
    'Auspicious Bunny',
    'Sugar Glider Mimi',
    'Blessed Dragon',
    'Felicity Nüwa', 
    'Halloween Pumpkin',
    'Fortuneteller',
    'Mysterious Merchant',
    'Otter Dodo',
    'Mister Roach',
    'Chacha',
    'Tiger of Blessings',
  ];

  /// Names for booth owners【625433312635769†L530-L606】.  These customers run booths
  /// in the town area and include stall owners like food vendors, artisans and
  /// shopkeepers.
  final List<String> boothOwners = [
    'Traditional Popcorn',
    'Old Joe',
    'Portrait Drawing Booth',
    'Sketch Artist',
    'Picnicking Rabbit',
    'Hillside’s Stinkiest',
    'Picnicking Duck',
    'Prosperity Pineapple',
    'Wholegrain Pancake',
    'Convenience Buns',
    'Love‑filled Buns',
    'Reverie Cotton Candy',
    'Slum Cotton Candy',
    'Stray Wild Panda',
    'Scavenging Skinny Dog',
    'Candied Hawthorn',
    'Mouse Market',
    'Flower Shop',
    'Bunny’s Back Garden',
    'Garden Plot',
    'Cut Cake',
    'Flora’s Ring Toss',
    'Bamboo Hot and Sour Noodles',
    'Terrible Pancake',
    'Japanese Cuisine',
    'Raccoon’s Takoyaki',
    'Rabbit’s Breakfast',
    'Hedgehog’s Breakfast',
    'Sweet Malt Candy',
    'Scavenging Puppies and Kitties',
    'Beancurd Dessert',
    'Bowl Pudding',
    'Ice Cream Stall',
    'Golden Fried Potatoes',
    'American Hot Dog',
    'Honeydew Shaved Ice',
    'Traditional Bowl Pudding',
    'Fresh Glutinous Rice Cake',
    'Egg Waffle',
    'Tailor Liu',
    'Love Salon',
    'Fried Quail Eggs',
    'Ice Cream Truck',
    'Street Stall Hiring',
    'Summer Iced Jelly',
    'Piggy’s Crawdads',
    'Skillful Massage',
    'Rainbow Shop Stationery',
    'Bicycle Repairs',
    'Encounters Photo Studio',
    'Love Tribe',
    'Fortunetelling',
    'Professional Protectors',
    'Gold Tooth Antiques',
    'Another Roujiamo',
    'Swift Roti Prata',
    'Trendy Braid',
    "Uncle’s Roasted Sweet Potato",
    'Inconspicuous Roasted Chestnuts',
    'Romantic Hot Air Balloon',
    "Budget Witchs Soup",
    'Sticky Rice Balls',
    'Ink Calligraphy',
  ];

  final List<String> seasonal = [
    'Praying Samoyed',
    'Tom',
    'Duke Swallow',
    'Mister Gecko',

  ];

  /// Names for performers【625433312635769†L617-L663】.  These characters are
  /// musicians or entertainers who play in bands or singing groups.
  final List<String> performers = [
    'Cutie White Bunny',
    'Cutie Hamster',
    'Cutie Goose',
    'Cutie Guru',
    'Little Piggy Angel',
    'Little Turtle Angel',
    'Little Yorkie Angel',
    'Little Shiba Angel',
    'Bassist Toad',
    'Guitarist Toad',
    'Vocalist Toad',
    'Drummer Toad',
    'Vocalist Samoyed',
    'Guitarist Husky',
    'Bassist Border Collie',
    'Accompanist Penguin',
    'Lead Dancer Slim White Dog',
    'Lead Singer Dalmatian',
    'Rapper Bean',
    'Leader Scotch Collie',
    'Leader Pug',
    'Guitarist Jackal',
    'Bassist Brown Wolf',
    'DJ Wolf',
  ];

  final List<String> staff = [
    'Messenger Hedwig',
    'Fisherman Rabbit Ding',
    'Jiji the Waiter',
    'Chef Gumi',
    'Timmy the Server',
    'Prince the Gardener',
    'Temp Worker Yolky',
    'Eggy the Handyman',
  ];


  List<String> allCustomers = [];
  Map<String, bool> _checked = {};


  @override
  void initState() {
    super.initState();
    _checked ??= {};
    
    // Combine all customer categories into
    //one list for the "All" subsection.
    allCustomers = [
      ...regularCustomers,
      ...specialCustomers,
      ...seasonal,
      ...boothOwners,
      ...performers,
    ];
    for (var name in allCustomers) {
    _checked[name] = false; // initialize all unchecked
  }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Customers section
            ExpansionTile(
              title: const Text('Customers'),
              children: [
                _buildCustomerSection('All', allCustomers),
                _buildCustomerSection('Restaurant', regularCustomers),
                _buildCustomerSection('Special', specialCustomers),
                _buildCustomerSection('Booth Owner', boothOwners),
                _buildCustomerSection('Seasonal', seasonal),
                _buildCustomerSection('Performer', performers),
              ],
            ),
            // Mementos section
            ExpansionTile(
              title: const Text('Mementos'),
              children: const [
                ListTile(
                  title: Text('Hidden Mementos (146 known)'),
                  subtitle: Text('Mementos hidden until certain conditions are met'),
                ),
                ListTile(
                  title: Text('Poster Mementos (80)'),
                  subtitle: Text('Unlocked after opening the Courtyard area'),
                ),
                ListTile(
                  title: Text('Redemption Code Mementos (22)'),
                ),
                ListTile(
                  title: Text('Event Mementos'),
                  subtitle: Text('Children’s Day, Dragon Boat, Halloween, etc.'),
                ),
              ],
            ),
            // Letters section
            ExpansionTile(
              title: const Text('Letters'),
              children: const [
                ListTile(
                  title: Text('Individual Letters (12 total)'),
                  subtitle: Text('Standalone letters not part of a series'),
                ),
                ListTile(
                  title: Text('Series Letters (215 total)'),
                  subtitle: Text('Grouped letters with story arcs'),
                ),
                ListTile(
                  title: Text('Newspaper Letters (10 total)'),
                ),
                ListTile(
                  title: Text('Holiday Letters (27 total)'),
                ),
                ListTile(
                  title: Text('Permissions to Raise Prices (22 total)'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a subsection of customers.  Each subsection is an expansion tile
  /// containing a list of customer names.  The `shrinkWrap` and
  /// `NeverScrollableScrollPhysics` settings ensure that the nested lists don’t
  /// conflict with the outer scroll view.
  Widget _buildCustomerSection(String title, List<String>? names) {
    final safeNames = names ?? [];
    return ExpansionTile(
      title: Text(title),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Center(
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 3,
              ),
              itemCount: safeNames.length,
              itemBuilder: (context, index) {
                final name = safeNames[index];
                final isChecked = _checked[name] ?? false;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _checked[name] = !isChecked;
                    });
                  },
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isChecked
                          ? Colors.green.withOpacity(0.6)
                          : Colors.yellow[100],
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: isChecked ? Colors.green : Colors.grey,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Checkbox(
                          value: isChecked,
                          onChanged: (_) {
                            setState(() {
                              _checked[name] = !isChecked;
                            });
                          },
                        ),
                        Flexible(
                          child: Text(
                            name,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }


}