import requests
import json
import unittest
import time

# Helper functions

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
                        turnOrder:list=[], guessedLetters:str='', 
                        isLobby:bool=True):

    # First check consistency of input
    if isLobby:
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
    for pid in turnOrder:
        test.assertIn(pid, state['turnOrder'])
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
        sid = check_post(self, 'new-session')

        # Get session state
        state = check_post(self, 'get-state', json={'sid': sid})

        # Check session state
        check_session_state(self, state, sid)

class TestJoinSession(unittest.TestCase):

    def setUp(self):
        self.sid = check_post(self, 'new-session')

    def test_single_join_session(self):
        # Join created session
        pid = check_post(self, 'join-session', {'sid': self.sid, 'name': 'uname'})

        # Get session state
        session_state = check_post(self, 'get-state', {'sid': self.sid})

        # Check session state
        check_session_state(self, session_state, sid=self.sid, players=[pid])

        # Check player state
        player_state = session_state['players'][pid]
        check_player_state(self, player_state, pid=pid, name='uname')

    def test_multiple_join_session(self):
        # Join created session
        pid1 = check_post(self, 'join-session', {'sid': self.sid, 'name': 'uname1'})
        pid2 = check_post(self, 'join-session', {'sid': self.sid, 'name': 'uname2'})

        # Get session state
        session_state = check_post(self, 'get-state', {'sid': self.sid})

        # Check session state
        check_session_state(self, session_state, sid=self.sid, players=[pid1, pid2])
        
        # Check player state
        for pid, name in zip([pid1, pid2], ['uname1', 'uname2']):
            player_state = session_state['players'][pid]
            check_player_state(self, player_state, pid=pid, name=name)

class TestSetWord(unittest.TestCase):
    
    def setUp(self):
        self.sid = check_post(self, 'new-session')

        self.username1 = 'test_username1'
        self.word1 = 'test_word1'

        self.username2 = 'test_username2'
        self.word2 = 'test_word2'

        self.username3 = 'test_username3'
        self.word3 = 'test_word3'

        self.usernames = [self.username1, self.username2, self.username3]
        self.words = [self.word1, self.word2, self.word3]

        json = {'sid': self.sid, 'name': self.username1}
        self.pid1 = check_post(self, 'join-session', json=json)

    def test_single_set_word(self):
        # Set word
        json = {'sid': self.sid, 'pid': self.pid1, 'word': self.word1}
        check_post(self, 'set-word', json=json)

        # Allow server to update
        time.sleep(0.05)

        # Get session state
        session_state = check_post(self, 'get-state', {'sid': self.sid})

        # Check session state
        check_session_state(self, session_state, sid=self.sid,
                            players=[self.pid1], turnOrder=[],
                            isLobby=True)

        # Check player state
        player_state = session_state['players'][self.pid1]
        check_player_state(self, player_state, pid=self.pid1,
                           name=self.username1,
                           word=self.word1, ready=True)

    def test_multiple_set_word_no_start(self):
        # Add two other players
        json = {'sid': self.sid, 'name': self.username2}
        pid2 = check_post(self, 'join-session', json=json)
        json = {'sid': self.sid, 'name': self.username3}
        pid3 = check_post(self, 'join-session', json=json)

        # Set words for two other players
        json = {'sid': self.sid, 'pid': self.pid1, 'word': self.word1}
        check_post(self, 'set-word', json=json)
        json = {'sid': self.sid, 'pid': pid2, 'word': self.word2}
        check_post(self, 'set-word', json=json)

        # Allow server to update
        time.sleep(0.05)

        # Get session state
        session_state = check_post(self, 'get-state', {'sid': self.sid})

        # Check session state
        check_session_state(self, session_state, sid=self.sid,
                            players=[self.pid1, pid2, pid3],
                            turnOrder=[], isLobby=True)

        # Check player states 
        zipped = zip([self.pid1, pid2, pid3], 
                     self.usernames, 
                     [self.word1, self.word2, ''])
        for pid, name, word in zipped:
            player_state = session_state['players'][pid]
            ready = word != ''
            check_player_state(self, player_state,
                               pid=pid, name=name,
                               word=word, ready=ready)

    def test_multiple_set_word_start(self):
        # Add two other players
        json = {'sid': self.sid, 'name': self.username2}
        pid2 = check_post(self, 'join-session', json=json)
        json = {'sid': self.sid, 'name': self.username3}
        pid3 = check_post(self, 'join-session', json=json)

        # Set words for two other players
        json = {'sid': self.sid, 'pid': self.pid1, 'word': self.word1}
        check_post(self, 'set-word', json=json)
        json = {'sid': self.sid, 'pid': pid2, 'word': self.word2}
        check_post(self, 'set-word', json=json)
        json = {'sid': self.sid, 'pid': pid3, 'word': self.word3}
        check_post(self, 'set-word', json=json)

        # Allow server to update
        time.sleep(0.05)

        # Get session state
        session_state = check_post(self, 'get-state', {'sid': self.sid})

        # Check session state
        check_session_state(self, session_state, sid=self.sid,
                            players=[self.pid1, pid2, pid3],
                            turnOrder=[self.pid1, pid2, pid3],
                            isLobby=False)

        # Check player states
        zipped = zip([self.pid1, pid2, pid3], self.usernames, self.words)
        for pid, name, word in zipped:
            player_state = session_state['players'][pid]
            check_player_state(self, player_state,
                               pid=pid, name=name,
                               word=word, ready=True)

class TestGuessWord(unittest.TestCase):

    def test_guess_letter_single_turn(self):
        pass


if __name__ == '__main__':
    unittest.main()



