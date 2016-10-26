class Ability
  include CanCan::Ability

  def initialize(user)

    # See the wiki for details:
    # https://github.com/ryanb/cancan/wiki/Defining-Abilities

    user ||= User.new

    if user.has_trex_admin?
      can :manage, :all
    else
      if user.has_demo?
        can :read, [IndustrySicCode, Map, TenantRecord]
      end

      if user.has_broker?
        can [:read, :update], Account, :user_id => user.id
        can :manage, TenantRecord, :team_id => user.account.teams.pluck(:id)
      end

      if user.has_analyst?
        #can :manage, Team, :office_id => user.account.office_id
        #can :manage, LeaseStructure
        can :manage, Map do |map|
          map.account_id == user.account.id || map.office_id == user.account.office_id
        end
        can :create, Map
        can :manage, TenantRecord do |record|
          record.office_id == user.account.office_id
        end
        can :create, TenantRecord
        can :manage, TenantRecordImport do |record_import|
          record_import.office.id == user.account.office_id
        end
        can :create, TenantRecordImport
        can :manage, ImportTemplate, :office_id => [user.account.office_id, nil]
        can :read, ImportTemplate, :office_id => [user.account.office_id, nil]
        can :create, ImportTemplate

        can [:read, :update], Office, :id => user.account.office_id, :firm_id => user.account.firm_id

        can :read, Account, :office_id => user.account.office_id

        can :manage, LeaseStructure, :office_id => user.account.office_id
        can :read, LeaseStructure, :office_id => nil
        can :manage, LeaseStructureExpense do |lse|
          user.account.office.lease_structures.map(&:id).include? lse.lease_structure_id
        end
        can :create, LeaseStructureExpense
        can :manage, Expense
      end

      if user.has_office_admin?
        #can :manage, Team, :office_id => user.account.office_id
        can :manage, Account, :office_id => user.account.office_id
        can :manage, Office, :id => user.account.office_id, :firm_id => user.account.firm_id
        can :manage, LeaseStructure, :office_id => user.account.office_id
        cannot :create, Office
        cannot :destroy, Office
      end

      if user.has_firm_admin?
        #can :manage, Team, :office_id => user.account.firm.offices.map(&:id)
        can :manage, Firm, :id == user.account.firm_id
        can :manage, Account, :firm_id => user.account.firm.id
        can :manage, LeaseStructure, :office_id => user.account.office_id

        cannot :create, Firm
        cannot :destroy, Firm
        can :create, Office
        can [:update, :read], Office, :firm_id => user.account.firm_id
        can :destroy, Office do |office|
          office.id != user.account.office_id
        end
      end
    end
  end
end
