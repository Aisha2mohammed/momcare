const { Model, DataTypes } = require('sequelize');

module.exports = (sequelize) => {
  class User extends Model {}

  User.init({
    id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
      primaryKey: true
    },
    role: {
      type: DataTypes.STRING(20),
      allowNull: false,
      defaultValue: 'mother'
    },
    name: {
      type: DataTypes.STRING(255)
    },
    phone: {
      type: DataTypes.STRING(50),
      unique: true
    },
    email: {
      type: DataTypes.STRING(255),
      unique: true
    },
    password_hash: {
      type: DataTypes.STRING(255)
    },
    language: {
      type: DataTypes.STRING(5),
      defaultValue: 'am'
    },
    status: {
      type: DataTypes.STRING(20),
      defaultValue: 'active'
    },
    firebase_uid: {
      type: DataTypes.STRING(255),
      unique: true
    },
    fcm_token: {
      type: DataTypes.STRING(500)
    },
    approved_by: {
      type: DataTypes.UUID
    },
    approved_at: {
      type: DataTypes.DATE
    },
    rejected_at: {
      type: DataTypes.DATE
    }
  }, {
    sequelize,
    modelName: 'User',
    tableName: 'users',
    timestamps: true,
    createdAt: 'created_at',
    updatedAt: 'updated_at'
  });

  User.associate = (models) => {
    User.hasOne(models.MotherProfile, {
      foreignKey: 'user_id',
      as: 'motherProfile'
    });
    User.hasOne(models.DoctorProfile, {
      foreignKey: 'user_id',
      as: 'doctorProfile'
    });
    User.belongsTo(models.User, {
      foreignKey: 'approved_by',
      as: 'approver'
    });
    User.hasMany(models.Appointment, {
      foreignKey: 'mother_id',
      as: 'motherAppointments'
    });
    User.hasMany(models.Appointment, {
      foreignKey: 'doctor_id',
      as: 'doctorAppointments'
    });
    User.hasMany(models.UserHealthLog, {
      foreignKey: 'mother_id',
      as: 'healthLogs'
    });
    User.hasMany(models.EmergencyContact, {
      foreignKey: 'mother_id',
      as: 'emergencyContacts'
    });
    User.hasMany(models.CommunityPost, {
      foreignKey: 'user_id',
      as: 'communityPosts'
    });
    User.hasMany(models.CommunityComment, {
      foreignKey: 'user_id',
      as: 'communityComments'
    });
    User.hasMany(models.Device, {
      foreignKey: 'user_id',
      as: 'devices'
    });
    User.hasMany(models.Reminder, {
      foreignKey: 'user_id',
      as: 'reminders'
    });
    User.hasMany(models.AuditLog, {
      foreignKey: 'admin_id',
      as: 'auditLogs'
    });
  };

  return User;
};
