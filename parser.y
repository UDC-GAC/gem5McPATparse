%{
#include <string.h>
#include <stdio.h>
#include <stdarg.h>
#include <stdlib.h>
#include <iostream>
#include <fstream>
#include <vector>
#include "lib/rapidxml.hpp"

using namespace rapidxml;
using namespace std;

#ifndef xml_temp
#define xml_temp "template.xml"
#endif

%}
%union {
    int t_int;
    double t_double;
    char * t_str;
}
%token EQ			
%token	<t_int> NUM
%token	<t_double> FLOAT
%token	<t_str> STR
// tokens types etc
%start S 			
%%
// rules
S : line { printf("finished parsing!\n"); }
  ;

/* left recursion better than right recursion: due to stack reasons */
line : /* empty */
;
%%
// C code

void xmlParser()
{
    cout << "Parsing my beer journal..." << endl;
    xml_document<> doc;
    xml_node<> * root_node;
    // Read the xml file into a vector
    ifstream theFile ("beerJournal.xml");
    vector<char> buffer((istreambuf_iterator<char>(theFile)), istreambuf_iterator<char>());
    buffer.push_back('\0');
    // Parse the buffer using the xml file parsing library into doc 
    doc.parse<0>(&buffer[0]);
    // Find our root node
    root_node = doc.first_node("MyBeerJournal");
    // Iterate over the brewerys
    for (xml_node<> * brewery_node = root_node->first_node("Brewery"); brewery_node; brewery_node = brewery_node->next_sibling())
	{
	    printf("I have visited %s in %s. ", 
		   brewery_node->first_attribute("name")->value(),
		   brewery_node->first_attribute("location")->value());
            // Interate over the beers
	    for(xml_node<> * beer_node = brewery_node->first_node("Beer"); beer_node; beer_node = beer_node->next_sibling())
		{
		    printf("On %s, I tried their %s which is a %s. ", 
			   beer_node->first_attribute("dateSampled")->value(),
			   beer_node->first_attribute("name")->value(), 
			   beer_node->first_attribute("description")->value());
		    printf("I gave it the following review: %s", beer_node->value());
		}
	    cout << endl;
	}
}

//////////////////////////
// main function
int main(int argc, char *argv[])
{
    // parse config.ini
    // parse stats.txt
    // fill template.xml
    return 0;
}
