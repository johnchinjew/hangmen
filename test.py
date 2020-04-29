import requests
import json
import unittest
import time

class TestNewSession(unittest.TestCase):
    
    def test_create(self):
        # Create new session
        res = requests.post("http://localhost:3000/new-session")
        self.assertEqual(res.headers['Content-Type'], 'text/html; charset=utf-8')
        self.assertNotEqual(len(res.text), 0)
        sid = res.text

        # Get session state
        json = {'sid': sid}
        res  = requests.post("http://localhost:3000/get-state", json=json)
        self.assertEqual(res.headers['Content-Type'], 'application/json; charset=utf-8')
        state = res.json()

        # Check session state
        for attr in ['id', 'players', 'turnOrder', 'alphabet', 'isLobby']:
            self.assertIn(attr, state)
        self.assertEqual(state['id'], sid)
        self.assertEqual(len(state['players']), 0)
        self.assertEqual(len(state['turnOrder']), 0)
        self.assertIn('letters', state['alphabet'])
        for c in 'abcdefghjiklmnopqrstuvwxyz':
            self.assertIn(c, state['alphabet']['letters'])
            self.assertFalse(state['alphabet']['letters'][c])
        self.assertTrue(state['isLobby'])

class TestJoinSession(unittest.TestCase):

    def setUp(self):
        res = requests.post("http://localhost:3000/new-session")
        self.sid = res.text

    def test_single_join_session(self):
        # Join created session
        json = {'sid': self.sid, 'name': 'test_username'}
        res = requests.post("http://localhost:3000/join-session", json=json)
        self.assertEqual(res.headers['Content-Type'], 'text/html; charset=utf-8')
        self.assertNotEqual(len(res.text), 0)
        pid = res.text

        # Get session state
        json = {'sid': self.sid}
        res = requests.post("http://localhost:3000/get-state", json=json)
        self.assertEqual(res.headers['Content-Type'], 'application/json; charset=utf-8')
        state = res.json()        

        # Check session state
        self.assertEqual(len(state['players']), 1)
        self.assertIn(pid, state['players'])

        # Check player state
        player = state['players'][pid]
        self.assertEqual(player['name'], 'test_username')
        self.assertEqual(player['word'], '')
        self.assertFalse(player['ready'])
        self.assertTrue(player['alive'])

    def test_multiple_join_session(self):
        # Join created session
        json = {'sid': self.sid, 'name': 'test_username1'}
        res = requests.post("http://localhost:3000/join-session", json=json)
        self.assertEqual(res.headers['Content-Type'], 'text/html; charset=utf-8')
        self.assertNotEqual(len(res.text), 0)
        pid1 = res.text

        json = {'sid': self.sid, 'name': 'test_username2'}
        res = requests.post("http://localhost:3000/join-session", json=json)
        self.assertEqual(res.headers['Content-Type'], 'text/html; charset=utf-8')
        self.assertNotEqual(len(res.text), 0)
        pid2 = res.text

        # Get session state
        json = {'sid': self.sid}
        res = requests.post("http://localhost:3000/get-state", json=json)
        self.assertEqual(res.headers['Content-Type'], 'application/json; charset=utf-8')
        state = res.json()        

        # Check session state
        self.assertEqual(len(state['players']), 2)
        self.assertIn(pid1, state['players'])
        self.assertIn(pid2, state['players'])

        # Check player state
        player1 = state['players'][pid1]
        self.assertEqual(player1['name'], 'test_username1')
        self.assertEqual(player1['word'], '')
        self.assertFalse(player1['ready'])
        self.assertTrue(player1['alive'])

        player2 = state['players'][pid2]
        self.assertEqual(player2['name'], 'test_username2')
        self.assertEqual(player2['word'], '')
        self.assertFalse(player2['ready'])
        self.assertTrue(player2['alive'])


class TestSetWord(unittest.TestCase):
    
    def setUp(self):
        res = requests.post("http://localhost:3000/new-session")
        self.sid = res.text

        self.username1 = 'test_username1'
        self.word1 = 'test_word1'

        self.username2 = 'test_username2'
        self.word2 = 'test_word2'

        self.username3 = 'test_username3'
        self.word3 = 'test_word3'

        json = {'sid': self.sid, 'name': self.username1}
        res = requests.post("http://localhost:3000/join-session", json=json)
        self.pid1 = res.text


    def test_single_set_word(self):
        # Set word
        json = {'sid': self.sid, 'pid': self.pid1, 'word': self.word1}
        res = requests.post("http://localhost:3000/set-word", json=json)
        self.assertEqual(res.headers['Content-Length'], '0')

        # Get session state
        json = {'sid': self.sid}
        res = requests.post("http://localhost:3000/get-state", json=json)
        self.assertEqual(res.headers['Content-Type'], 'application/json; charset=utf-8')
        state = res.json()        

        # Allow server to update
        time.sleep(0.05)

        # Check session state
        self.assertEqual(len(state['players']), 1)
        self.assertIn(self.pid1, state['players'])
        self.assertTrue(state['isLobby'])

        # Check player state
        player = state['players'][self.pid1]
        self.assertEqual(player['name'], self.username1)
        self.assertEqual(player['word'], self.word1)
        self.assertTrue(player['ready'])
        self.assertTrue(player['alive'])

    def test_multiple_set_word_no_start(self):
        # Add two other players
        json = {'sid': self.sid, 'name': self.username2}
        pid2 = requests.post("http://localhost:3000/join-session", json=json).text
        json = {'sid': self.sid, 'name': self.username3}
        pid3 = requests.post("http://localhost:3000/join-session", json=json).text

        # Set words for two other players
        json = {'sid': self.sid, 'pid': self.pid1, 'word': self.word1}
        res = requests.post("http://localhost:3000/set-word", json=json)
        self.assertEqual(res.headers['Content-Length'], '0')
        json = {'sid': self.sid, 'pid': pid2, 'word': self.word2}
        res = requests.post("http://localhost:3000/set-word", json=json)
        self.assertEqual(res.headers['Content-Length'], '0')

        # Allow server to update
        time.sleep(0.05)

        # Get session state
        json = {'sid': self.sid}
        res = requests.post("http://localhost:3000/get-state", json=json)
        self.assertEqual(res.headers['Content-Type'], 'application/json; charset=utf-8')
        state = res.json()    

        # Check session state
        self.assertEqual(len(state['players']), 3)
        for pid in [self.pid1, pid2, pid3]:
            self.assertIn(pid, state['players'])
        self.assertTrue(state['isLobby'])

        # Check player state
        player1 = state['players'][self.pid1]
        self.assertEqual(player1['name'], self.username1)
        self.assertEqual(player1['word'], self.word1)
        self.assertTrue(player1['ready'])
        self.assertTrue(player1['alive'])

        player2 = state['players'][pid2]
        self.assertEqual(player2['name'], self.username2)
        self.assertEqual(player2['word'], self.word2)
        self.assertTrue(player2['ready'])
        self.assertTrue(player2['alive'])

        player3 = state['players'][pid3]
        self.assertEqual(player3['name'], self.username3)
        self.assertEqual(player3['word'], '')
        self.assertFalse(player3['ready'])
        self.assertTrue(player3['alive'])

    def test_multiple_set_word_start(self):
        # Add two other players
        json = {'sid': self.sid, 'name': self.username2}
        pid2 = requests.post("http://localhost:3000/join-session", json=json).text
        json = {'sid': self.sid, 'name': self.username3}
        pid3 = requests.post("http://localhost:3000/join-session", json=json).text

        # Set words for two other players
        json = {'sid': self.sid, 'pid': self.pid1, 'word': self.word1}
        res = requests.post("http://localhost:3000/set-word", json=json)
        self.assertEqual(res.headers['Content-Length'], '0')
        json = {'sid': self.sid, 'pid': pid2, 'word': self.word2}
        res = requests.post("http://localhost:3000/set-word", json=json)
        self.assertEqual(res.headers['Content-Length'], '0')
        json = {'sid': self.sid, 'pid': pid3, 'word': self.word3}
        res = requests.post("http://localhost:3000/set-word", json=json)
        self.assertEqual(res.headers['Content-Length'], '0') 

        # Allow server to update
        time.sleep(0.05)

        # Get session state
        json = {'sid': self.sid}
        res = requests.post("http://localhost:3000/get-state", json=json)
        self.assertEqual(res.headers['Content-Type'], 'application/json; charset=utf-8')
        state = res.json()    

        # Check session state
        self.assertEqual(len(state['players']), 3)
        for pid in [self.pid1, pid2, pid3]:
            self.assertIn(pid, state['players'])
        self.assertEqual(len(state['turnOrder']), 3)
        self.assertFalse(state['isLobby'])

        # Check player state
        player1 = state['players'][self.pid1]
        self.assertEqual(player1['name'], self.username1)
        self.assertEqual(player1['word'], self.word1)
        self.assertTrue(player1['ready'])
        self.assertTrue(player1['alive'])

        player2 = state['players'][pid2]
        self.assertEqual(player2['name'], self.username2)
        self.assertEqual(player2['word'], self.word2)
        self.assertTrue(player2['ready'])
        self.assertTrue(player2['alive'])

        player3 = state['players'][pid3]
        self.assertEqual(player3['name'], self.username3)
        self.assertEqual(player3['word'], self.word3)
        self.assertTrue(player3['ready'])
        self.assertTrue(player3['alive'])


if __name__ == '__main__':
    unittest.main()

# # Check player join functionality
# sid = requests.post("http://localhost:3000/new-session")
# print("new-session:", sid.text)

# pid = requests.post("http://localhost:3000/join-session", json={'sid': sid.text, 'name': 'joji'})
# print("join-session:", pid.text)


