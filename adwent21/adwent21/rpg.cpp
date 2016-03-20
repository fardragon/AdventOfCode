#include "rpg.h"

Character::Character(int hp, int atk, int def)
{
	hitpoints = hp;
	damage = atk;
	armor = def;
}

void Character::set_armor(int def)
{
	armor += def;
}

void Character::set_weapon(int atk)
{
	damage += atk;
}

void Character::set_ring(int atk, int def)
{
	damage += atk;
	armor += def;
}

bool Character::check_dead()
{
	if ( hitpoints <= 0 )
	{
		return true;
	}
	return false;
}

int Character::get_dmg()
{
	return damage;
}

int Character::get_arm()
{
	return armor;
}

int Character::get_hp()
{
	return hitpoints;
}








void attack(Character*& attacker, Character*& defender)
{
	int hit = attacker->damage - defender->armor;
	if ( hit <= 0 ) hit = 1;
	defender->hitpoints -= hit;
}