const { Model, DataTypes } = require('sequelize');

module.exports = (sequelize) => {
  class DoctorAvailabilitySlot extends Model {}

  DoctorAvailabilitySlot.init({
    id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
      primaryKey: true
    },
    doctor_id: {
      type: DataTypes.UUID,
      allowNull: false
    },
    day_of_week: {
      type: DataTypes.INTEGER,
      allowNull: false
    },
    start_time: {
      type: DataTypes.TIME,
      allowNull: false
    },
    end_time: {
      type: DataTypes.TIME,
      allowNull: false
    },
    slot_duration_minutes: {
      type: DataTypes.INTEGER,
      defaultValue: 30
    },
    is_active: {
      type: DataTypes.BOOLEAN,
      defaultValue: true
    }
  }, {
    sequelize,
    modelName: 'DoctorAvailabilitySlot',
    tableName: 'doctor_availability_slots',
    timestamps: true,
    createdAt: 'created_at',
    updatedAt: 'updated_at'
  });

  DoctorAvailabilitySlot.associate = (models) => {
    DoctorAvailabilitySlot.belongsTo(models.User, {
      foreignKey: 'doctor_id',
      as: 'doctor'
    });
  };

  return DoctorAvailabilitySlot;
};
