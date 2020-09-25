% Takes a FullLeg object and turns its point cloud markers into joint angles in the same manner as NWdata
% Demonstrates the consistent offset between Animatlab and NW measurements

nn = 1;
for ii = 1:length(obj.theta_motion)
    mkSimp(1,:) = obj.musc_obj{37}.pos_attachments{1,4}(ii,:);
    mkSimp(2,:) = obj.joint_obj{1}.sim_position_profile(ii,:);
    mkSimp(3,:) = obj.joint_obj{2}.sim_position_profile(ii,:);
    mkSimp(4,:) = obj.joint_obj{3}.sim_position_profile(ii,:);
    mkSimp(5,:) = obj.musc_obj{20}.pos_attachments{5,4}(ii,:);
    for jj = 2:4
        v1 = mkSimp(jj-1,:)-mkSimp(jj,:);
        v2 = mkSimp(jj+1,:)-mkSimp(jj,:);
        outMotion(nn,jj-1) = (180/pi)*acos(dot(v1,v2)/(norm(v1(1:2))*norm(v2(1:2))));
    end
    nn = nn +1;
end