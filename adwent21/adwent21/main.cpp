#include "rpg.h"

using namespace std;


int main()
{
	const Item Weapons[] = { { "Dagger", 4, 0,8 },{"Shortsword",5,0,10},{ "Warhammer",6,0,25 },{ "Longsword",7,0,40 },{ "Greataxe",8,0,74 } };
	const Item Armors[] = { { "NO_ARMOR", 0, 0,0 },{ "Leather", 0, 1,13 } , { "Chainmail", 0, 2,31 },{ "Splintmail",0,3,53 },{ "Bandedmail",0,4,75 },{ "Platemail",0,5,102 } };
	const Item Rings[] = { {"NO_RING1",0,0,0},{"NO_RING2",0,0,0},{"Def+1",0,1,20},{ "Def+2",0,2,40 },{ "Def+3",0,3,80 },{ "Dmg+1",1,0,25 },{ "Dmg+2",2,0,50 },{ "Dmg+3",3,0,100 } };
	Character* player = nullptr;
	Character* boss = nullptr;
	int current_cost;
	int best_cost = INT32_MAX;
	bool won = false;
	int weapon, armor, ring1, ring2;
	int bweapon, barmor, bring1, bring2;

	for ( weapon = 0; weapon < 5; weapon++ )
	{
		for ( armor = 0; armor < 6; armor++ )
		{
			for ( ring1 = 0; ring1 < 8; ring1++ )
			{
				for ( ring2 = 0; ring2 < 8; ring2++ )
				{
					if ( ring1 == ring2 ) continue;

					player = new Character(100, 0, 0);
					player->set_weapon(Weapons[weapon].atk);
					player->set_armor(Armors[armor].def);
					player->set_ring(Rings[ring1].atk, Rings[ring1].def);
					player->set_ring(Rings[ring2].atk, Rings[ring2].def);
					boss = new Character(103, 9, 2);

					while ( true )
					{
					//	cout << "Player deals: " << player->get_dmg() << " - " << boss->get_arm() << " = " << player->get_dmg() - boss->get_arm() << " damage. Boss goes down to:  ";
						attack(player, boss);
					//  cout << boss->get_hp() << " hp." << endl;
						if ( boss->check_dead() )
						{
							won = true;
							break;
						}
						//cout << "Boss deals: " << boss->get_dmg() << " - " << player->get_arm() << " = " << boss->get_dmg() - player->get_arm() << " damage. Player goes down to:  ";
						attack(boss, player);
						//cout << player->get_hp() << " hp." << endl;
						if ( player->check_dead() )
						{
							won = false;
							break;
						}
					}
					delete player;
					delete boss;
					if ( won )
					{
						current_cost = Weapons[weapon].cost + Armors[armor].cost + Rings[ring1].cost + Rings[ring2].cost;
						cout << "Won with: " << current_cost << " gold" << endl;
						if ( current_cost < best_cost )
						{
							best_cost = current_cost;
							bweapon = weapon;
							barmor = armor;
							bring1 = ring1;
							bring2 = ring2;
						}
					}
					
					



				}
			}
		}
	}
	cout << "Best cost: " << best_cost << " Gold " << endl;
	cout << "Weapon: " << Weapons[bweapon].name << endl;
	cout << "Armor: " << Armors[barmor].name << endl;
	cout << "Ring 1: " << Rings[bring1].name << endl;
	cout << "Ring 2: " << Rings[bring2].name << endl;


	system("pause");
	return 0;
}