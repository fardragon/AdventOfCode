#ifndef RPG
#define RPG
#include <iostream>
#include <string>

class Character
{
	int hitpoints;
	int damage;
	int armor;

	public:
	
	Character(int=100,int=0,int=0);
	void set_weapon(int);
	void set_armor(int);
	void set_ring(int, int);
	bool check_dead();
	friend void attack(Character*&, Character*&);
	int get_hp();
	int get_dmg();
	int get_arm();


};


struct Item
{
	std::string name;
	int atk;
	int def;
	int cost;
};











#endif