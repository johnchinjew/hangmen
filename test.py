import requests
import json
import unittest
import time

# Helper functions
def new_session(test: unittest.TestCase):
    return check_post(test, 'new-session')

def join_session(test: unittest.TestCase,
                 sid: str,
                 name: str):
    json = {'sid': sid, 'name': name}
    return check_post(test, 'join-session', json=json)

def get_state(test: unittest.TestCase,
              sid: str):
    json = {'sid': sid}
    return check_post(test, 'get-state', json=json)

def set_word(test: unittest.TestCase,
             sid: str,
             pid: str, 
             word: str):
    json = {'sid': sid, 'pid': pid, 'word': word}
    return check_post(test, 'set-word', json=json)

def guess_letter(test: unittest.TestCase,
                 sid: str,
                 letter: str):
    json = {'sid': sid, 'letter': letter}
    return check_post(test, 'guess-letter', json=json)

def guess_word(test: unittest.TestCase,
               sid: str,
               pid: str,
               word: str):
    json = {'sid': sid, 'pid': pid, 'word': word}
    return check_post(test, 'guess-word', json=json)

def exit_session(test: unittest.TestCase,
                 sid: str,
                 pid: str):
    json = {'sid': sid, 'pid': pid}
    return check_post(test, 'exit-session', json=json)

def reset_session(test: unittest.TestCase,
                  sid: str):
    json = {'sid': sid}
    return check_post(test, 'reset-session', json=json)

def check_post(test: unittest.TestCase,
               post_type: str,
               json: dict=None):
    res, content_type = None, None
    if post_type == 'new-session':
        assert(json is None)
        content_type = 'text/html'
    elif post_type == 'join-session':
        assert(json is not None and 'sid' in json 
               and 'name' in json)
        content_type = 'text/html'
    elif post_type == 'get-state':
        assert(json is not None and 'sid' in json)
        content_type = 'application/json'
    elif post_type == 'set-word':
        assert(json is not None and 'sid' in json 
               and 'pid' in json and 'word' in json)
    elif post_type == 'guess-letter':
        assert(json is not None and 'sid' in json 
               and 'letter' in json)
    elif post_type == 'guess-word':
        assert (json is not None and 'sid' in json
                and 'pid' in json and 'word' in json)
    elif post_type == 'exit-session':
        assert (json is not None and 'sid' in json
                and 'pid' in json)
    elif post_type == 'reset-session':
        assert (json is not None and 'sid' in json)
    else:
        raise ValueError()
    res = requests.post(f'http://localhost:3000/{post_type}', json=json)
    return check_response(test, res, content_type)

def check_response(test: unittest.TestCase,
                    res: requests.Response,
                    content_type:str=None):
    res_data = None
    if content_type is None:
        test.assertNotIn('Content-Type', res.headers)
    else:
        test.assertIn('Content-Type', res.headers)
        test.assertEqual(res.headers['Content-Type'], content_type+'; charset=utf-8')
        test.assertNotEqual(len(res.text), 0)
        if content_type == 'text/html':
            res_data = res.text
        elif content_type == 'application/json':
            res_data = res.json()
        else:
            raise ValueError()
    return res_data
    
def check_session_state(test: unittest.TestCase, 
                        state: dict, sid:str=None, players:list=[],
                        turnOrderContains:list=None, turnOrder:list=None,
                        guessedLetters:str='', isLobby:bool=True):

    # First check consistency of input
    assert(not ((turnOrderContains is not None) and ((turnOrder is not None))))
    if isLobby:
        if turnOrderContains is not None:
            assert(len(turnOrderContains) == 0)
        if turnOrder is not None:
            assert(len(turnOrder) == 0)
        assert(len(guessedLetters) == 0)

    # Run equality check on state using input
    for attr in ['id', 'players', 'turnOrder', 'alphabet', 'isLobby']:
        test.assertIn(attr, state)
    if sid is not None:
        test.assertEqual(state['id'], sid)
    test.assertEqual(len(state['players']), len(players))
    for pid in players: 
        test.assertIn(pid, state['players'])
    # Cannot check ACTUAL turn order (since it is shuffled)
    # only check if they both contain same elements
    if turnOrderContains is not None:
        for pid in turnOrderContains:
            test.assertIn(pid, state['turnOrder'])
    if turnOrder is not None:
        test.assertEqual(state['turnOrder'], turnOrder)
    for c in 'abcdefghjiklmnopqrstuvwxyz':
        test.assertIn(c, state['alphabet']['letters'])
        if c in guessedLetters:
            test.assertTrue(state['alphabet']['letters'][c])
        else:
            test.assertFalse(state['alphabet']['letters'][c])
    test.assertEqual(state['isLobby'], isLobby)

def check_player_state(test: unittest.TestCase,
                       state: dict, pid: str, name: str,
                       word:str='', ready:bool=False, alive:bool=True):
    for attr in ['id', 'name', 'word', 'ready', 'alive']:
        test.assertIn(attr, state)
    if pid is not None:
        test.assertEqual(state['id'], pid)
    test.assertEqual(state['word'], word)
    test.assertEqual(state['ready'], ready)
    test.assertEqual(state['alive'], alive)

class TestNewSession(unittest.TestCase):
    
    def test_create(self):
        # Create new session
        sid = new_session(self)

        # Get session state
        session_state = get_state(self, sid)

        # Check session state
        check_session_state(self, session_state, sid)

class TestJoinSession(unittest.TestCase):

    def setUp(self):
        self.sid = check_post(self, 'new-session')

    def test_single_join_session(self):
        # Join created session
        pid = join_session(self, self.sid, 'name')

        # Get session state
        session_state = check_post(self, 'get-state', {'sid': self.sid})

        # Check session state
        check_session_state(self, session_state, sid=self.sid, players=[pid])

        # Check player state
        player_state = session_state['players'][pid]
        check_player_state(self, player_state, pid=pid, name='name')

    def test_multiple_join_session(self):
        # Join created session
        pid1 = join_session(self, self.sid, 'name1')
        pid2 = join_session(self, self.sid, 'name2')

        # Get session state
        session_state = get_state(self, self.sid)

        # Check session state
        check_session_state(self, session_state, sid=self.sid, players=[pid1, pid2])
        
        # Check player state
        for pid, name in zip([pid1, pid2], ['name1', 'name2']):
            player_state = session_state['players'][pid]
            check_player_state(self, player_state, pid=pid, name=name)

    def test_join_active_session(self):

        # Create active session
        pids = [None] * 3
        names = ['name1', 'name2', 'name3']
        words = ['word1', 'word2', '']
        readies = [True, True, False]
        pids[0] = join_session(self, self.sid, names[0])
        pids[1] = join_session(self, self.sid, names[1])
        set_word(self, self.sid, pids[0], words[0])
        set_word(self, self.sid, pids[1], words[1])

        time.sleep(0.05)

        # Session now active,
        # Last player joins
        pids[2] = join_session(self, self.sid, names[2])

        # Check session state
        session_state = get_state(self, self.sid)
        check_session_state(self, session_state,
                            sid=self.sid,
                            players=pids, 
                            turnOrderContains=pids[:2], 
                            isLobby=False)

        # Check player states
        for pid, name, word, ready in zip(pids, names, words, readies):
            player_state = session_state['players'][pid]
            check_player_state(self, player_state, 
                               pid=pid, name=name,
                               word=word, ready=ready)

class TestSetWord(unittest.TestCase):
    
    def setUp(self):
        self.sid = check_post(self, 'new-session')

        self.names = ['name1', 'name2', 'name3']
        self.words = ['word1', 'word2', 'word3']
        self.pids = [None, None, None]

    def test_single_set_word(self):
        # Join and set word
        self.pids[0] = check_post(self, 'join-session', 
                                    {'sid': self.sid, 'name': self.names[0]})

        set_word(self, self.sid, self.pids[0], self.words[0])

        # Allow server to update
        time.sleep(0.05)

        # Get session state
        session_state = get_state(self, self.sid) 

        # Check session state
        check_session_state(self, session_state, sid=self.sid,
                            players=self.pids[:1], 
                            turnOrderContains=[],
                            isLobby=True)

        # Check player state
        player_state = session_state['players'][self.pids[0]]
        check_player_state(self, player_state, pid=self.pids[0],
                           name=self.names[0],
                           word=self.words[0], ready=True)

    def test_multiple_set_word_no_start(self):
        
        # All players join
        for i in range(3):
            self.pids[i] = join_session(self, self.sid, self.names[i])

        # First two players set word
        for i in range(2):
            set_word(self, self.sid, self.pids[i], self.words[i])

        # Allow server to update
        time.sleep(0.05)

        # Get session state
        session_state = get_state(self, self.sid)

        # Check session state
        check_session_state(self, session_state, sid=self.sid,
                            players=self.pids,
                            turnOrderContains=[], 
                            isLobby=True)

        # Check player states 
        self.words = self.words[:2] + ['']
        for pid, name, word in zip(self.pids, self.names, self.words):
            player_state = session_state['players'][pid]
            ready = word != ''
            check_player_state(self, player_state,
                               pid=pid, name=name,
                               word=word, ready=ready)

    def test_multiple_set_word_start(self):
        
        # All players join
        for i in range(3):
            self.pids[i] = join_session(self, self.sid, self.names[i])

        # All players set word
        for i in range(3):
            set_word(self, self.sid, self.pids[i], self.words[i])

        # Allow server to update
        time.sleep(0.05)

        # Get session state
        session_state = get_state(self, self.sid)

        # Check session state
        check_session_state(self, session_state, sid=self.sid,
                            players=self.pids,
                            turnOrderContains=self.pids,
                            isLobby=False)

        # Check player states
        for pid, name, word in zip(self.pids, self.names, self.words):
            player_state = session_state['players'][pid]
            check_player_state(self, player_state,
                               pid=pid, name=name,
                               word=word, ready=True)

class TestGuessLetter(unittest.TestCase):

    def setUp(self):

        # Set up active game
        self.sid = new_session(self)
        self.pids = [None] * 3
        self.names = ['name' + str(i) for i in range(1,4)]
        self.words = ['banana', 'apple', 'cashew']
        for i in range(3):
            self.pids[i] = join_session(self, self.sid, self.names[i])
        for i in range(3):
            set_word(self, self.sid, self.pids[i], self.words[i])
        self.turnOrder = None
        
    def test_guess_letter_single_turn(self):

        # Get turnOrder
        session_state = get_state(self, self.sid)
        turnOrder = session_state['turnOrder']
        # Update turnOrder to eventual state
        turnOrder = turnOrder[1:] + turnOrder[:1]
        
        # Single letter
        guess_letter(self, self.sid, 'a')

        time.sleep(0.05)

        # Check session state
        session_state = get_state(self, self.sid)
        check_session_state(self, session_state, sid=self.sid,
                            players=self.pids, 
                            turnOrder=turnOrder,
                            guessedLetters='a',
                            isLobby=False)

        # Check player states
        for pid, name, word in zip(self.pids, self.names, self.words):
            player_state = session_state['players'][pid] 
            check_player_state(self, player_state, 
                               pid=pid, name=name,
                               word=word, ready=True,
                               alive=True)

    def test_guess_letter_multiple_turns(self):
        
        # Get turnOrder
        session_state = get_state(self, self.sid)
        turnOrder = session_state['turnOrder']
        # Update turnOrder to eventual state 
        for _ in range(3):
            turnOrder = turnOrder[1:] + turnOrder[:1]

        # Guess letter 3 times
        for c in 'abc':
            guess_letter(self, self.sid, c)

        time.sleep(0.05)

        # Check session state
        session_state = get_state(self, self.sid)
        check_session_state(self, session_state, sid=self.sid,
                            players=self.pids,
                            turnOrder=turnOrder,
                            guessedLetters='abc',
                            isLobby=False)

        # Check player states (all alive)
        for pid, name, word in zip(self.pids, self.names, self.words):
            player_state = session_state['players'][pid]
            check_player_state(self, player_state,
                               pid=pid, name=name,
                               word=word, ready=True,
                               alive=True)

    def test_guess_letter_multiple_turns_duplicate(self):

        # Get turnOrder
        session_state = get_state(self, self.sid)
        turnOrder = session_state['turnOrder']
        # Update turnOrder to eventual state 
        for _ in range(3):
            turnOrder = turnOrder[1:] + turnOrder[:1]

        # Guess letter 4 times, but only 3 should be processed
        for c in 'abbc':
            guess_letter(self, self.sid, c)

        time.sleep(0.05)

        # Check session state
        session_state = get_state(self, self.sid)
        check_session_state(self, session_state, sid=self.sid,
                            players=self.pids,
                            turnOrder=turnOrder,
                            guessedLetters='abc',
                            isLobby=False)

        # Check player states (all alive)
        for pid, name, word in zip(self.pids, self.names, self.words):
            player_state = session_state['players'][pid]
            check_player_state(self, player_state,
                               pid=pid, name=name,
                               word=word, ready=True,
                               alive=True)

    def test_guess_letter_multiple_turns_kill(self):
        
        # Get turnOrder
        session_state = get_state(self, self.sid)
        turnOrder = session_state['turnOrder']
        # Update turnOrder to eventual state 
        for _ in range(2):
            turnOrder = turnOrder[1:] + turnOrder[:1]
        turnOrder.remove(self.pids[0]) # We kill player 1
        turnOrder = turnOrder[1:] + turnOrder[:1]

        # Guess letter 4 times, but only 3 should be processed
        for c in 'ban':
            guess_letter(self, self.sid, c)
            
        time.sleep(0.05)

        # Check session state
        session_state = get_state(self, self.sid)
        check_session_state(self, session_state, sid=self.sid,
                            players=self.pids,
                            turnOrder=turnOrder,
                            guessedLetters='ban',
                            isLobby=False)

        # Check player states (first dead)
        alives = [False, True, True]
        for pid, name, word, alive in zip(self.pids, self.names,
                                   self.words, alives):
            player_state = session_state['players'][pid]
            check_player_state(self, player_state,
                               pid=pid, name=name,
                               word=word, ready=True,
                               alive=alive)


if __name__ == '__main__':
    unittest.main()



