import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:steven/game/game.dart';

class StevenRule extends StatefulWidget {
  final Game game;
  const StevenRule(this.game, {super.key});

  @override
  State<StevenRule> createState() => _StevenRuleState();
}

class _StevenRuleState extends State<StevenRule> {
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
        listenable: widget.game,
        builder: (context, _) {
          return Column(children: [
            InkWell(
                onTap: () {
                  widget.game.isCurrentTurn() && widget.game.currentCard == null
                      ? widget.game.conn.socket.sink
                          .add(jsonEncode({"DrawCard": widget.game.lobby.pin}))
                      : widget.game.currentCard != null
                          ? widget.game.conn.socket.sink.add(
                              jsonEncode({"PassTurn": widget.game.lobby.pin}))
                          : null;
                },
                child: SizedBox(
                    height: 400,
                    width: 280,
                    child: widget.game.isCurrentTurn()
                        ? GameCard.build(widget.game.currentCard)
                        : const Text("Not you turn"))),
          ]);
        });
  }
}

enum CardColor {
  hearts,
  diamonds,
  spades,
  clubs,
}

class GameCard {
  final int i;
  final CardColor color;

  const GameCard(this.i, this.color);

  static Widget build(GameCard? currentCard) {
    return Container(
        height: 400,
        decoration: currentCard == null
            ? BoxDecoration(
                border: Border.all(
                    color: const Color.fromARGB(255, 78, 79, 97), width: 5),
                borderRadius: const BorderRadius.all(Radius.circular(15)),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment(0.8, 1),
                  colors: <Color>[
                    Color(0xff1f005c),
                    Color(0xff5b0060),
                    Color(0xff870160),
                    Color(0xffac255e),
                    Color(0xffca485c),
                    Color(0xffe16b5c),
                    Color(0xfff39060),
                    Color(0xffffb56b),
                  ], // Gradient from https://learnui.design/tools/gradient-generator.html
                  tileMode: TileMode.mirror,
                ))
            : BoxDecoration(
                border: Border.all(
                    color: Color.fromARGB(255, 78, 79, 97), width: 5),
                color: Color.fromARGB(255, 40, 37, 51),
                borderRadius: const BorderRadius.all(Radius.circular(15))),
        child: currentCard == null
            ? const Center(child: Text("Draw your card"))
            : Center(
                child: Stack(children: [
                Align(
                    alignment: Alignment.topLeft, child: currentCard.getIcon()),
                Align(
                    alignment: Alignment.center,
                    child: SizedBox(
                        width: 260, child: Text(currentCard.toString())))
              ])));
  }

  Widget getIcon() {
    var icon = color == CardColor.hearts
        ? const Icon(
            Icons.favorite,
            color: Colors.pink,
            size: 50,
          )
        : color == CardColor.spades
            ? const Icon(
                Icons.construction,
                color: Color.fromARGB(255, 24, 124, 173),
                size: 50,
              )
            : color == CardColor.diamonds
                ? const Icon(
                    Icons.bakery_dining_rounded,
                    color: Colors.pink,
                    size: 50,
                  )
                : const Icon(
                    Icons.spa,
                    color: Color.fromARGB(255, 24, 124, 173),
                    size: 50,
                  );
    return icon;
  }

  @override
  String toString() {
    String colorName = "";
    if (color == CardColor.clubs) {
      colorName = "Clubs";
    } else if (color == CardColor.diamonds) {
      colorName = "Diamonds";
    } else if (color == CardColor.hearts) {
      colorName = "Hearts";
    } else if (color == CardColor.spades) {
      colorName = "Spades";
    }
    if (i == 13) {
      return "King of $colorName\n\n You are now the King";
    } else if (i == 12) {
      return "Queen of $colorName\n\n All ladies Cheers!!";
    } else if (i == 11) {
      return "Jack\n\n All gentlemen Cheers!!";
    } else if (i == 0) {
      return "Welcome to a game of Steven";
    } else if (i == 1) {
      return "ES of $colorName\n\n You got a Sniper\n\n With this cand you can snip another player";
    } else if (i == 3) {
      return "3 of $colorName\n\n Blind or mute\n\n You can decide to be blind or mute, until the next '3' is drawn\n Penalty for violating is 4 sips!";
    } else if (i == 2) {
      if (color == CardColor.clubs || color == CardColor.spades) {
        return "2 of $colorName\n\n You must drink 2 sips!";
      } else {
        return "2 of $colorName\n\n You can give away 2 sips";
      }
    } else if (i == 4) {
      return "4 of $colorName\n\n \"Thumb\"\n\n At any time you can place your thumb of the edge of the table,\n the last person to also place their thumb on the table must drink 4 sips";
    } else if (i == 5) {
      return "5 of $colorName\n\n \"Viking\"\n\n At any time you can use your hands to form viking horns\n The last person to start rowing must drink 4 sips";
    } else if (i == 6) {
      return "6 of $colorName\n\n \"Wall\"\n\n At any time you may touch a wall and shout \"Wall\"\n The last person to also touch a wall must drink 4 sips";
    } else if (i == 7) {
      return "STEVEN\n\n You are Steven! \n Meaning you are paralyzed, you must appoint a 'helper' that will help you with EVERYTING! \n Feeling thirsty? The helper will help you drink \n Need to you the restroom? Your helper will carry you if that's what it takes \n Anything else in the game, No worries you've got a helper! \n\n You will remain Steven until another person is chosen to be Steven.";
    } else if (i == 8) {
      return "8 of $colorName\n\n \"Date\"\n\n Choose a person that you are on a date with, the two of you will have to take all your sips together!";
    } else if (i == 9) {
      return "9 of $colorName\n\n \"Min Pik er\" or \"My Dick is\"\n\n You have to start a sentace with \"Min Pik er\" followed by a word that describes you penis \n Every other player will have to find a new word with the same starting letter to describe their penis \n This continues until someone fail to find a word \n The penalty for loosing is 4 sips";
    } else if (i == 10) {
      return "10 of $colorName\n\n \"Category\"\n\n Pick a category and name a thing from the category, the next person has to find a new thing in the category and so on \n repetintiopn of a thing that has already been said \n or not being able to come up with anything \n will result in a penalty of 4 sips";
    }
    return i.toString();
  }
}

/*

Es - Tag én tår

2'er - Er den sort skal du tage 2 tåre selv ellers må du give dem ud.

3'er - Blind eller stum! Du må selv vælge. Reglen gælder til næste 3'er er trukket.

Enhver overtrædelse kræver 4 tåre.

4'er - Tommelfinger. Du skal beholde kortet og på et tidspunkt i spillet sætte din tommelfinger på bordet.
Den sidste der sætter sin tommelfinger på bordet skal drikke 4 tåre.

5'er - Viking. Du skal gemme kortet og på et tidspunkt bruge dine hænder til at forme vikingehorn på dit hovede.
Den sidste der begynder at ro voldsomt med deres hænder skal drikke 4 tåre.

6'er - Væg. Du skal beholde kortet og på et tidspunkt røre væggen og råbe 'VÆG'. Den sidste der rør en væg skal drikke 4 tåre.

7'er - Steven. Du er nu lam og skal udnævne en 'Spasser passer' som skal hjælpe dig med alt. Drikke, gå på toilettet, udfører spillet osv.

'Spasser passer' berhøver ikke lave ting som 'væg' og 'viking' hvis spilleren hjælper dig.

Du er Steven til næste 7'er er trukket.

8'er - Date. Du skal nu vælge en spiller at være på date med resten af spillet. I skal tage alle tåre sammen.

9'er - Min pik er. Du vælger hvad 'min pik er' og så går den på tur.
Hver spiller skal bruge samme forbogstav som spilleren der trak kortet brugte.

fx ( Min pink er Stor. Så kan næste sige 'min pik er Slap' ...Skarp ...Stærk. osv...)
Hvis man ikke kan komme på noget der ikke er sagt eller det ikke giver gramatisk mening skal man tage 4 tåre og runden er ovre.

10'er
Kategori. Vælg en kategori og lad den gå på runde. Spilleren der ikke kan komme med noget nyt fra kategorien eller siger noget der alle er sagt taber og skal tage 4 tåre.

Bonde - terodactyl/joke. Vælg en spiller du skal få til at grine. Du kan vælge mellem at sige og aggere som en terodactyl eller fortælle en joke til spilleren.

Dronning

Tissekort. Du må bruge kortet som billet til toilettet.

Konge
Regl. Du må lave en regl i spillet. Den må ikke være person specifik! Reglen gælder resten af spillet
 */

class CardDeck {
  late final List<GameCard> cards;

  CardDeck() {
    cards = List.empty(growable: true);
    for (CardColor color in CardColor.values) {
      for (int i = 1; i <= 13; i++) {
        cards.add(GameCard(i, color));
      }
    }
  }

  GameCard cardAtIndex(int index) {
    return cards[index];
  }

  int length() {
    return cards.length;
  }

  void removeCard(GameCard card) {
    cards.remove(card);
  }

  @override
  String toString() {
    return cards.toString();
  }
}
