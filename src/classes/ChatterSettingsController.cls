public class ChatterSettingsController {
    
    public List<GroupEmailFrequency> groupEmailFrequencyList { get; set; }
    public ConnectApi.UserDetail userDetail { get; set; }
    
    private NetworkMember preferences;
    
    public Boolean commentsOnMyPost { get; set; }
    public Boolean commentsAfterMe { get; set; }
    
    private String communityId;
    
    public ChatterSettingsController() {
        communityId = CommonsChatterUtil.getWGUCommonsCommunityId();
        populateEmailFrequencyList();
        populateChatterSettings();
        userDetail = ConnectApi.UserProfiles.getUserProfile(communityId, UserInfo.getUserId()).userDetail;
    }
    
    private void populateEmailFrequencyList() {
        groupEmailFrequencyList = new List<GroupEmailFrequency>();
        Map<String, String>groupMap = CommonsChatterUtil.getUserGroupMap();
        for(String groupId : groupMap.keySet()) {
            ConnectApi.GroupChatterSettings settings = ConnectApi.ChatterGroups.getMyChatterSettings(communityId, groupId);
            groupEmailFrequencyList.add(new GroupEmailFrequency(groupId, groupMap.get(groupId), settings.emailFrequency));
        }
    }
    
    private void populateChatterSettings() {
        String userId = UserInfo.getUserId();
        preferences = [SELECT PreferencesDisableLaterCommentEmail,PreferencesDisProfPostCommentEmail FROM NetworkMember WHERE MemberId = :userId AND NetworkId = :communityId];
        commentsOnMyPost = !preferences.PreferencesDisProfPostCommentEmail;
        commentsAfterMe = !preferences.PreferencesDisableLaterCommentEmail;
    }
    
    public void saveChanges() {
        boolean updated = false;
        if(preferences.PreferencesDisProfPostCommentEmail == commentsOnMyPost) { //result is inverted from original
            preferences.PreferencesDisProfPostCommentEmail = !commentsOnMyPost;
            updated = true;
        }
        
        if(preferences.PreferencesDisableLaterCommentEmail == commentsAfterMe) { //result is inverted from original
            preferences.PreferencesDisableLaterCommentEmail = !commentsAfterMe;
            updated = true;
        }
        
        if(updated) {
            update preferences;
        }
        
        for(GroupEmailFrequency setting : groupEmailFrequencyList) {
            if(setting.updated()) {
                ConnectApi.ChatterGroups.updateMyChatterSettings(communityId, setting.groupId, setting.emailFrequency);
            }
        }
    }
    
    public void actionChangeEmailFrequency() {
        String groupId = Apexpages.currentPage().getParameters().get('groupId');
        String emailFrequency = Apexpages.currentPage().getParameters().get('emailFrequency');
        for(GroupEmailFrequency freq : groupEmailFrequencyList) {
            if(freq.groupId.equals(groupId)) {
                if(emailFrequency.equalsIgnoreCase('Each Post')) {
                    freq.emailFrequency = ConnectApi.GroupEmailFrequency.EachPost;
                }
                else if(emailFrequency.equalsIgnoreCase('Daily Digest')) {
                    freq.emailFrequency = ConnectApi.GroupEmailFrequency.DailyDigest;
                }
                else if(emailFrequency.equalsIgnoreCase('Weekly Digest')) {
                    freq.emailFrequency = ConnectApi.GroupEmailFrequency.WeeklyDigest;
                }
                break;
            }
        }
    }
    
    public class GroupEmailFrequency {
        
        public String groupId { get; set; }
        public String groupName { get; set; }
        public ConnectApi.GroupEmailFrequency emailFrequency { get; set; }
        private ConnectApi.GroupEmailFrequency origEmailFrequency;
        
        public GroupEmailFrequency(String groupId, String groupName, ConnectApi.GroupEmailFrequency emailFrequency) {
            this.groupId = groupId;
            this.groupName = groupName;
            this.emailFrequency = emailFrequency;
            origEmailFrequency = emailFrequency;
        }
        
        public Boolean updated() {
            return emailFrequency != origEmailFrequency;
        }
        
        public String getDisplayFrequency() {
            if(emailFrequency == ConnectApi.GroupEmailFrequency.EachPost) {
                return 'Each Post';
            }
            if(emailFrequency == ConnectApi.GroupEmailFrequency.DailyDigest) {
                return 'Daily Digest';
            }
            if(emailFrequency == ConnectApi.GroupEmailFrequency.WeeklyDigest) {
                return 'Weekly Digest';
            }
            return 'Never';
        }
    
    }
    
}