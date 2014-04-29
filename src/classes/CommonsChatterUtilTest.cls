@IsTest
public class CommonsChatterUtilTest {

    @IsTest static void getWGUCommonsCommunityIdTest() {
        Network community = [SELECT id FROM Network WHERE name = 'WGU Commons'];
        
        String result = CommonsChatterUtil.getWGUCommonsCommunityId();
        System.assertEquals(community.id, result);
    }
    
    @IsTest static void getGroupOptionsTest() {
        Map<String, String> groupMap = new Map<String, String>();
        groupMap.put('1', 'Group 1');
        groupMap.put('2', 'Group 2');
        
        List<SelectOption> optionList = CommonsChatterUtil.getGroupOptions(groupMap);
        System.assertEquals(2, optionList.size());
        
        //The rest of the values are not neccessarily in order because of the map
        boolean expectedValues = true;
        for(SelectOption option : optionList) {
            if(option.getValue().equals('1') && option.getLabel().equals('Group 1')) {
                continue;
            }
            else if(option.getValue().equals('2') && option.getLabel().equals('Group 2')) {
                continue;
            }
            else if(option.getValue().equals('') && option.getLabel().equals('')) {
                continue;
            }
            expectedValues = false;
        }
        System.assert(expectedValues);
    }
    
    @IsTest static void checkForQuestionUpdateTest() {
        FeedItem feedItem1 = new FeedItem();
        feedItem1.body = 'I asked a question';
        feedItem1.parentId = UserInfo.getUserId();
        insert feedItem1;
    
        FeedComment comment1 = new FeedComment();
        comment1.feedItemId = feedItem1.id;
        comment1.commentBody = 'I left a comment';
        insert comment1;
                
        CommunityAccessControl__c cac1 = new CommunityAccessControl__c();
        cac1.originalPostId__c = feedItem1.id;
        cac1.postStatus__c = 'Waiting for Clarification';
        insert cac1;
        
        FeedComment comment = [SELECT id, insertedById, commentBody, feedItemId FROM FeedComment WHERE id = :comment1.id];
        Test.startTest();
        CommonsChatterUtil.checkForQuestionUpdate(String.valueOf(comment.id), comment.commentBody);
        Test.stopTest();
        
        CommunityAccessControl__c result = [SELECT PostStatus__c, StudentResponse__c FROM CommunityAccessControl__c WHERE id = :cac1.id];
        System.assertEquals('Student Responded', result.postStatus__c);
        System.assertEquals('I left a comment', result.studentResponse__c);
    }
    
    @IsTest static void getIdFromUserSummaryTest() {
        String userSummary = 'ConnectApi.UserSummary[buildVersion=29.0, companyName=null, firstName=Bill, id=005a0000009IVMmAAO, isActive=true, isInThisCommunity=true, lastName=Poindexter, motif=ConnectApi.Motif[buildVersion=29.0, color=20aeb8, largeIconUrl=/img/icon/profile64.png, mediumIconUrl=/img/icon/profile32.png, smallIconUrl=/img/icon/profile16.png], mySubscription=null, name=Bill Poindexter, photo=ConnectApi.Photo[buildVersion=29.0, fullEmailPhotoUrl=https://srm--DevFull.cs15.my.salesforce.com/img/userprofile/default_profile_200.png?fromEmail=1, largePhotoUrl=https://srm--DevFull--c.cs15.content.force.com/profilephoto/005/F, photoVersionId=null, smallPhotoUrl=https://srm--DevFull--c.cs15.content.force.com/profilephoto/005/T, standardEmailPhotoUrl=https://srm--DevFull.cs15.my.salesforce.com/img/userprofile/default_profile_45.png?fromEmail=1, url=/services/data/v29.0/connect/communities/0DBe00000008ONjGAM/chatter/users/005a0000009IVMmAAO/photo], title=null, type=User, url=/services/data/v29.0/connect/communities/0DBe00000008ONjGAM/chatter/users/005a0000009IVMmAAO, userType=Portal]';
    
        CommonsChatterUtil util = new CommonsChatterUtil();
        String result = util.getIdFromUserSummary(userSummary);
        System.assertEquals('005a0000009IVMmAAO', result);
    }
    
    /*@IsTest(SeeAllData=true) static void getUserGroupMapTest() {
        Map<String, String> resultMap = CommonsChatterUtil.getUserGroupMap();
        System.assertEquals(0, resultMap.size());
    }*/

}