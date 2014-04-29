public class GroupMemberWithUserType {
    
    public ConnectApi.GroupMember member { get; set; }
    public boolean isStudent { get; set; }
    
    public GroupMemberWithUserType(ConnectApi.GroupMember member, boolean isStudent) {
        this.member = member;
        this.isStudent = isStudent;
    }
    
}