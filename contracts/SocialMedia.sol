// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

contract SocialMedia {
  
    struct Content {
        uint id;
        uint date;
        address author;
        string content;
        bytes32[] hashtags;
    }

    uint latestContentId;
    address[] public users;
    Content[] public contents;
    bytes32[] public hashtags;

    mapping(address => bytes32[]) public subscribedHashtags;
    mapping(bytes32 => uint) public hashtagScore;
    mapping(bytes32 => Content[]) public contentListByHashtag;
    mapping(uint => Content) public contentById;
    mapping(bytes32 => bool) public doesHashtagExist;
    mapping(address => bool) public doesUserExist;

    event ContentAddded(uint indexed id, address indexed author, uint indexed date, string content, bytes32[] hashtags);

    /**
     * Add content to the dApp, if no hashtag is sent, add it to the general list.
     * @param _content: The string of the content
     * @param _hashtags: The hashtags that are attached to the content
     */
    function addContent(string memory _content, bytes32[] memory _hashtags) public {
        require(bytes(_content).length > 0, "Content is empty");
        Content memory content = Content(latestContentId, now, msg.sender, _content, _hashtags);

        if (_hashtags.length == 0) {
            contentListByHashtag['general'].push(content);
            hashtagScore['general']++;
            if (!doesHashtagExist['general']) {
                hashtags.push('general');
                doesHashtagExist['general'] = true;
            }
        } else {
            for(uint i = 0; i < _hashtags.length; i++) {
                contentListByHashtag[_hashtags[i]].push(content);
                hashtagScore[_hashtags[i]]++;
                if (!doesHashtagExist[_hashtags[i]]) {
                    hashtags.push(_hashtags[i]);
                    doesHashtagExist[_hashtags[i]] = true;
                }
            }
        }

        hashtags = sortHashtagsByScore(); // not sure if this should happen here or be filtered out in frontend
        contentById[latestContentId] = content;
        contents.push(content);
        if (!doesUserExist[msg.sender]) {
            users.push(msg.sender);
            doesUserExist[msg.sender] = true;
        }
        emit ContentAddded(latestContentId, msg.sender, now, _content, _hashtags);
        latestContentId++;
    }

    /**
     * Subscribe to a hashtag if it has not happened yet.
     * @param _hashtag: Name of the hashtag
     */
     function subscribeToHashtag(bytes32 _hashtag) public {
         require(!checkExistingSubscription(_hashtag), "Already subscribed");
         subscribedHashtags[msg.sender].push(_hashtag);
         hashtagScore[_hashtag]++;
         hashtags = sortHashtagsByScore();
     }

     /**
      * Unsubscribe to a hashtag, requires to have been subscribed
      * @param _hashtag: Name of hashtag
      */
      function unsubscribeToHashtag(bytes32 _hashtag) public {
         require(checkExistingSubscription(_hashtag), "You are not subscribed to this hashtag");
         for(uint i = 0; i < subscribedHashtags[msg.sender].length; i++) {
             if (subscribedHashtags[msg.sender][i] == _hashtag) {
                 delete subscribedHashtags[msg.sender][i];
                 hashtagScore[_hashtag]--;
                 hashtags = sortHashtagsByScore();
                 break;
             }
         }
      }

    /**
     * Get top hashtags
     * @param _amount: Amount of top hashtags to retrieve
     * @return bytes32[]: Returns the top x hashtags by amount
     */
      function getTopHashtags(uint _amount) public view returns (bytes32[] memory) {
          bytes32[] memory result = new bytes32[];
          if (hashtags.length < _amount) {
              for (uint i = 0; i < hashtags.length; i++) {
                  result[i] = hashtags[i];
              }
          } else {
              for (uint i = 0; i < _amount; i++) {
                  result[i] = hashtags[i];
              }
          }
          return result;
      }

    /**
     * Get content ids by hash tag, we cannot return structs so we will just return the ids here so the frontend can
     * fetch these one by one (but combined e.g. rxjs forkJoin)
     * @param _hashtag: Get content by hastag
     * @param _amount: Limit the amount of content ids by this amount
     * @return uint[]: Returns the list of ids
     */
      function getContentIdsByHashtag(bytes32 _hashtag, uint _amount) public view returns (uint[] memory) {
          uint[] memory ids = new uint[];
          for(uint i = 0; i < _amount; i++) {
              ids.push(contentListByHashtag[_hashtag][i].id);
          }
          return ids;
      }

    /**
     * Get all data of content by the given id
     * @param _id: The id of the content
     * @return uint, uint, address, string, bytes32[]: Return the id, date, author, content and hashtags of the struct
     */
      function getContentById(uint _id) public view returns (uint, uint, address, string memory, bytes32[] memory) {
          Content memory content = contentById(_id);
          return (content.id, content.date, content.author, content.content, content.hashtags);
      }

     /**
      * Wondering if this cant be done by frontend  as well as this uses gas..
      * @return bytes32[]: Returns sorted list of hashtags by score
      */
      function sortHashtagsByScore() private returns (bytes32) {
          bytes32[] memory _hashtags = hashtags;
          bytes32[] memory sorted = new bytes32[];
          uint listId = 0;
          for(uint i = 0; i < _hashtags.length; i++) {
              for(uint j = 0; j < _hashtags.length; j++) {
                  if(hashtagScore[_hashtags[i]] < hashtagScore[_hashtags[j]]) {
                      bytes32 temp = _hashtags[i];
                      _hashtags[i] = _hashtags[j];
                      _hashtags[j] = temp;
                  }
              }
              sorted[listId] = _hashtags[i];
              listId++;
          }
          return sorted;
      }

    /**
     * Checks if you are subscribed to a hashtag
     * NOTE: Do NOT call this function in another view function, this function needs a transaction so that 
     * msg.sender works. If this is called by another view, msg.sender does not exist
     * @param _hashtag: The hashtag you want to check if you are subscribed to it
     * @return bool: Returns if the current user is subscribed to the given hastag
     */
      function checkExistingSubscription(bytes32 _hashtag) private view returns (bool) {
          for(uint i = 0; i < subscribedHashtags[msg.sender]; i++) {
              if (subscribedHashtags[msg.sender][i] == _hashtag) {
                  return true;
              }
          }
          return false;
      }
}
