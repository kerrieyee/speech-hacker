class AttendancesController < ApplicationController
  def create
    @meeting = Meeting.find(params[:meeting_id])
    params[:attendance].merge!(:meeting => @meeting, :user => current_user)
    @attendance = Attendance.new(params[:attendance])

    if @attendance.save
      notice = @attendance.attend ? "See you there!" : "Sorry you won't be there."
      redirect_to meetings_path(@meeting), :notice => notice
    else
      @meeting_roles = MeetingRole.attendee_roles
      render "meetings/show", :alert => "Something went wrong!"
    end
  end

  def update
    @attendance = current_user.attendances.find(params[:id])

    if @attendance.update_attributes(params[:attendance])
      # If role changed from speaker to non-speaker, remove db record
      notice = @attendance.attend ? "See you there!" : "Sorry you won't be there."
      redirect_to meetings_path, :notice => notice
    else
      @meeting = @attendance.meeting
      @meeting_roles = MeetingRole.attendee_roles
      render "meetings/show", :alert => "Something went wrong!"
    end
  end

  def update_role
    @meeting = Meeting.find(params[:id])
    @role    = MeetingRole.find(params[:role_id])

    if params[:old_user_id] == ""
      # This is the case that we go from "Select a member" to a new role.
      @user = User.find(params[:user_id])
      success = add_new_attendance(@meeting, @user, @role)
      remove_attendee = @user
    elsif params[:old_user_id] != "" && params[:user_id] == ""
      # This is the case that we remove a user with an assigned role.
      # We need to change the old_user to Attendee role.
      @old_user = User.find(params[:old_user_id])
      success   = update_single_attendance(@meeting, @old_user, MeetingRole.attendee)
      remove_attendee = @old_user
      new_attendee = @old_user if !@old_user.attendance_for_meeting(@meeting).attendee?
    else
      # This is the case that we re-assign a role from user A to user B.
      @user     = User.find(params[:user_id])
      @old_user = User.find(params[:old_user_id])
      success   = update_attendances(@meeting, @old_user, @user, @role)
      remove_attendee = @user
      new_attendee = @old_user if !@user.attendance_for_meeting(@meeting).attendee?
    end

    respond_to do |format|
      format.json do
        if success.errors.empty?
          logger.info("new attendee: ")
          logger.info(new_attendee.name) if new_attendee
          render :json => {
                            :role => @role,
                            :remove_attendee => (remove_attendee || ""),
                            :new_attendee => (new_attendee || ""),
                            :success => true
                          }
        else
          render :json => {
                            :errors => success.errors.full_messages.join(', '),
                            :status => :unprocessable_entity
                          }
        end
      end
    end
  end

  private

  def add_new_attendance(meeting, user, meeting_role)
    # It's possible that the user that we try to assign a new role to
    # already has a role, so check if this user already has an attendance
    # in this meeting.
    attendance = meeting.attendances.where(:user_id => user.id).first
    if attendance
      # If there is already an existing attendance for this user at this
      # meeting, simply update the attendance record instead of
      # creating a new one.
      attendance = update_single_attendance(meeting, user, meeting_role)
    else
      # Create a new attendance for this user for this meeting only if
      # a record that fits this criteria does not exist already.
      attendance = Attendance.create(:attend => "true", :user => user, :meeting_role => meeting_role,
                                     :meeting => meeting)
    end
    attendance
  end

  def update_single_attendance(meeting, user, meeting_role)
    attendance = meeting.attendances.where(:user_id => user.id).first
    attendance.update_attributes(:attend => "true", :user => user, :meeting_role => meeting_role,
                                  :meeting_role_id => meeting_role.id)
    attendance
  end

  def update_attendances(meeting, old_user, user, meeting_role)
    # Find attendances for user A and user B.
    attendance1 = meeting.attendances.where(:user_id => old_user.id).first
    attendance2 = meeting.attendances.where(:user_id => user.id).first

    # Since this is an update involving two existing users, we need to first
    # remove user B's record, or else our database will complain that
    # an attendance already exists for user B.
    attendance2.delete if attendance2

    # Update the new user's role using the old user's attendance record
    attendance1.update_attributes(:attend => "true", :user => user, :meeting_role => meeting_role,
                                  :meeting_role_id => meeting_role.id)

    # By the time we get here, user A's original attendance record would have
    # been changed to user B. Thus, we need to create a new attendance record
    # for user A, and with the Attendee role.
    # The end result is that user B has user A's old role,
    # and user A has the attendee role.
    add_new_attendance(meeting, old_user, MeetingRole.attendee)

    attendance1
  end
end
