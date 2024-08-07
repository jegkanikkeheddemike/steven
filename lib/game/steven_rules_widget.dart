import 'dart:convert';

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
        return Column(
          children: [
            InkWell(
              onTap: switch ((
                widget.game.isCurrentTurn(),
                widget.game.currentCard
              )) {
                (false, var _) => null,
                (true, null) => () {
                    widget.game.conn.socket.sink
                        .add(jsonEncode({"DrawCard": widget.game.lobby.pin}));
                  },
                (true, var _) => () {
                    widget.game.conn.socket.sink
                        .add(jsonEncode({"PassTurn": widget.game.lobby.pin}));
                  }
              },
              child: SizedBox(
                height: 400,
                width: 280,
                child: widget.game.isCurrentTurn()
                    ? GameCard.build(widget.game.currentCard)
                    : const Center(child: Text("Not your turn")),
              ),
            ),
          ],
        );
      },
    );
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
                  colors: [
                    Color(0xff1f005c),
                    Color(0xff5b0060),
                    Color(0xff870160),
                    Color(0xffac255e),
                    Color(0xffca485c),
                    Color(0xffe16b5c),
                    Color(0xfff39060),
                    Color(0xffffb56b),
                  ],
                  tileMode: TileMode.mirror,
                ))
            : BoxDecoration(
                border: Border.all(
                    color: const Color.fromARGB(255, 78, 79, 97), width: 5),
                color: const Color.fromARGB(255, 40, 37, 51),
                borderRadius: const BorderRadius.all(Radius.circular(15))),
        child: currentCard == null
            ? const Center(child: Text("Draw your card"))
            : Center(
                child: Stack(children: [
                Align(
                    alignment: Alignment.topLeft,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        currentCard.getIcon(),
                        const Spacer(),
                        Text(currentCard.name()),
                        const Spacer(),
                        currentCard.getIcon(),
                      ],
                    )),
                Align(
                    alignment: Alignment.center,
                    child: SizedBox(
                        width: 240,
                        child: Center(
                            child: Text(
                          currentCard.toString(),
                          style: TextStyle(fontSize: 20),
                        )))),
              ])));
  }

  Widget getIcon() {
    var icon = color == CardColor.hearts
        ? const Image(width: 50, image: AssetImage('assets/HEARTS.png'))
        : color == CardColor.spades
            ? const Image(width: 50, image: AssetImage('assets/SPADES.png'))
            : color == CardColor.diamonds
                ? const Image(
                    width: 50, image: AssetImage('assets/DIAMONDS.png'))
                : const Image(width: 50, image: AssetImage('assets/CLUBS.png'));
    return icon;
  }

  String name() {
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
      return "King of $colorName";
    }
    if (i == 12) {
      return "Queen of $colorName";
    }
    if (i == 11) {
      return "Jack of $colorName";
    }
    if (i == 7) {
      return "STEVEN";
    }
    if (i == 1) {
      return "Ace of $colorName";
    }
    return "$i of $colorName";
  }

  @override
  String toString() {
    if (i == 13) {
      return "You are now the King";
    } else if (i == 12) {
      return "All ladies Cheers!!";
    } else if (i == 11) {
      return "All gentlemen Cheers!!";
    } else if (i == 0) {
      return "Welcome to a game of Steven";
    } else if (i == 1) {
      return "Sniper\n\nWith this card you can snip another player";
    } else if (i == 3) {
      return "Blind or mute\n\nYou can decide to be blind or mute, until the next '3' is drawn\n Penalty for violating is 4 sips!";
    } else if (i == 2) {
      if (color == CardColor.clubs || color == CardColor.spades) {
        return "You must drink 2 sips!";
      } else {
        return "You can give away 2 sips";
      }
    } else if (i == 4) {
      return "\"Thumb\"\n\n At any time you can place your thumb of the edge of the table,\n the last person to also place their thumb on the table must drink 4 sips";
    } else if (i == 5) {
      return "\"Viking\"\n\n At any time you can use your hands to form viking horns\n The last person to start rowing must drink 4 sips";
    } else if (i == 6) {
      return "Wall\n\nAt any time you may touch a wall and shout \"Wall\"\nThe last person to also touch a wall must drink 4 sips";
    } else if (i == 7) {
      return "You are paralyzed, you must appoint a 'helper' to will help you with EVERYTHING!\n\nYou will remain Steven until another person is chosen to be Steven.";
      // Feeling thirsty? The helper will help you drink \n Need to you the restroom? Your helper will carry you if that's what it takes \n Anything else in the game, No worries you've got a helper! \n\n
    } else if (i == 8) {
      return "Date\n\nChoose a person to go on a date with\nThe two of you will share all penalties";
    } else if (i == 9) {
      return "\"Min Pik er...\"\n\nFinish the sentence \"Min Pik er...\"\nTake turns, all words must have the same starting letter, as the first word\nThe penalty for loosing is 4 sips";
    } else if (i == 10) {
      return "\"Category\"\nPick a category and name a thing from the category, the next person has to find a new thing in the category and so on \nRepetitions or inability to continue will end the game and the loser drinks 4 sips";
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
